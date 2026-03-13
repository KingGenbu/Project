'use strict';

// ── Heavy I/O dependencies – mocked so tests run without binaries / file system
jest.mock('fluent-ffmpeg');
jest.mock('sharp');
jest.mock('rmdir', () => jest.fn());
jest.mock('node-ffprobe', () => jest.fn());
jest.mock('fs', () => ({
  mkdirSync: jest.fn(),
  renameSync: jest.fn(),
  existsSync: jest.fn().mockReturnValue(false),
  unlink: jest.fn(),
}));

// Model mocks
jest.mock('../../modules/feed/feedListModel', () => ({
  find: jest.fn(() => ({ remove: jest.fn().mockResolvedValue({}) })),
  aggregate: jest.fn().mockResolvedValue([]),
  insertMany: jest.fn().mockResolvedValue([]),
}));
jest.mock('../../modules/feed/feedModel', () => ({
  aggregate: jest.fn().mockResolvedValue([]),
}));

jest.mock('../../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
}));

const feedUtils = require('../../modules/feed/feedUtils');

// ─── filterDocs() ─────────────────────────────────────────────────────────────
// This is the most testable function in feedUtils: pure transformation, no I/O.

describe('feedUtils.filterDocs()', () => {
  it('returns an empty array when input is empty', () => {
    expect(feedUtils.filterDocs([])).toEqual([]);
  });

  it('filters out docs that have no stories and no liveStreams', () => {
    const docs = [
      { stories: [], liveStreams: [] },
      { stories: [], liveStreams: [] },
    ];
    expect(feedUtils.filterDocs(docs)).toHaveLength(0);
  });

  it('keeps a doc that has at least one non-empty story', () => {
    const doc = {
      stories: [{ _id: 'story-1', feedType: 'StoryImage' }],
      liveStreams: [],
    };
    const result = feedUtils.filterDocs([doc]);
    expect(result).toHaveLength(1);
    expect(result[0].stories).toHaveLength(1);
  });

  it('keeps a doc that has at least one non-empty liveStream', () => {
    const doc = {
      stories: [],
      liveStreams: [{ _id: 'live-1', feedType: 'LiveStream' }],
    };
    const result = feedUtils.filterDocs([doc]);
    expect(result).toHaveLength(1);
    expect(result[0].liveStreams).toHaveLength(1);
  });

  it('keeps a doc that has both stories and liveStreams', () => {
    const doc = {
      stories: [{ _id: 'story-1' }],
      liveStreams: [{ _id: 'live-1' }],
    };
    const result = feedUtils.filterDocs([doc]);
    expect(result).toHaveLength(1);
  });

  it('removes empty objects from the stories array', () => {
    const doc = {
      stories: [
        { _id: 'story-1' },
        {}, // empty – should be stripped
        { _id: 'story-2' },
      ],
      liveStreams: [],
    };
    const result = feedUtils.filterDocs([doc]);
    expect(result[0].stories).toHaveLength(2);
    result[0].stories.forEach((s) => expect(s._id).toBeDefined());
  });

  it('removes empty objects from the liveStreams array', () => {
    const doc = {
      stories: [],
      liveStreams: [
        {}, // empty
        { _id: 'live-1' },
      ],
    };
    const result = feedUtils.filterDocs([doc]);
    expect(result[0].liveStreams).toHaveLength(1);
    expect(result[0].liveStreams[0]._id).toBe('live-1');
  });

  it('excludes a doc once all its stories have been stripped as empty', () => {
    const doc = {
      stories: [{}, {}], // all empty
      liveStreams: [],
    };
    expect(feedUtils.filterDocs([doc])).toHaveLength(0);
  });

  it('handles multiple docs and returns only non-empty ones', () => {
    const docs = [
      { stories: [{ _id: 'story-1' }], liveStreams: [] }, // keep
      { stories: [], liveStreams: [] },                    // discard
      { stories: [], liveStreams: [{ _id: 'live-1' }] },  // keep
      { stories: [{}], liveStreams: [] },                  // discard (story is empty object)
    ];
    const result = feedUtils.filterDocs(docs);
    expect(result).toHaveLength(2);
  });

  it('mutates the stories array on the original doc objects', () => {
    const doc = { stories: [{}, { _id: 's1' }], liveStreams: [{ _id: 'l1' }] };
    feedUtils.filterDocs([doc]);
    // filterDocs writes the cleaned array back onto doc.stories
    expect(doc.stories).toHaveLength(1);
    expect(doc.stories[0]._id).toBe('s1');
  });
});

// ─── deleteTempFiles() ────────────────────────────────────────────────────────

describe('feedUtils.deleteTempFiles()', () => {
  it('calls rmdir with the provided path', () => {
    const rmdir = require('rmdir');
    feedUtils.deleteTempFiles('/tmp/my-upload-folder');
    expect(rmdir).toHaveBeenCalledWith('/tmp/my-upload-folder');
  });
});

// ─── generateScreenShot() ────────────────────────────────────────────────────

describe('feedUtils.generateScreenShot()', () => {
  beforeEach(() => {
    jest.resetModules();
    jest.clearAllMocks();
  });

  it('resolves with the rotated filename on success (shouldRotate = false)', async () => {
    const mockSharpInstance = {
      rotate: jest.fn().mockReturnThis(),
      toFile: jest.fn().mockImplementation((dest, cb) => cb(null)),
    };
    const sharp = require('sharp');
    sharp.mockImplementation(() => mockSharpInstance);

    const ffmpeg = require('fluent-ffmpeg');
    const mockFfmpegInstance = {
      on: jest.fn().mockReturnThis(),
      takeScreenshots: jest.fn().mockReturnThis(),
    };
    ffmpeg.mockImplementation(() => mockFfmpegInstance);

    // Capture the event handlers
    let filenamesHandler, endHandler;
    mockFfmpegInstance.on.mockImplementation((event, handler) => {
      if (event === 'filenames') filenamesHandler = handler;
      if (event === 'end') endHandler = handler;
      return mockFfmpegInstance;
    });

    const promise = feedUtils.generateScreenShot('/tmp/video.mp4', '/tmp/frames', false);

    // Simulate ffmpeg firing events
    filenamesHandler(['thumb_001.jpg']);
    endHandler();

    const result = await promise;
    expect(result).toBe('rotate_thumb_001.jpg');
  });

  it('rejects when sharp fails to write the rotated file', async () => {
    const mockSharpInstance = {
      rotate: jest.fn().mockReturnThis(),
      toFile: jest.fn().mockImplementation((dest, cb) => cb(new Error('write failed'))),
    };
    const sharp = require('sharp');
    sharp.mockImplementation(() => mockSharpInstance);

    const ffmpeg = require('fluent-ffmpeg');
    const mockFfmpegInstance = { on: jest.fn().mockReturnThis(), takeScreenshots: jest.fn().mockReturnThis() };
    ffmpeg.mockImplementation(() => mockFfmpegInstance);

    let filenamesHandler, endHandler;
    mockFfmpegInstance.on.mockImplementation((event, handler) => {
      if (event === 'filenames') filenamesHandler = handler;
      if (event === 'end') endHandler = handler;
      return mockFfmpegInstance;
    });

    const promise = feedUtils.generateScreenShot('/tmp/video.mp4', '/tmp/frames', false);
    filenamesHandler(['thumb_001.jpg']);
    endHandler();

    await expect(promise).rejects.toThrow('write failed');
  });

  it('rejects when ffmpeg emits an error event', async () => {
    const ffmpeg = require('fluent-ffmpeg');
    const mockFfmpegInstance = { on: jest.fn().mockReturnThis(), takeScreenshots: jest.fn().mockReturnThis() };
    ffmpeg.mockImplementation(() => mockFfmpegInstance);

    let errorHandler;
    mockFfmpegInstance.on.mockImplementation((event, handler) => {
      if (event === 'error') errorHandler = handler;
      return mockFfmpegInstance;
    });

    const promise = feedUtils.generateScreenShot('/tmp/video.mp4', '/tmp/frames', false);
    errorHandler(new Error('ffmpeg crashed'));

    await expect(promise).rejects.toThrow('ffmpeg crashed');
  });
});
