'use strict';

// ── Mock aws-sdk before any require() loads it ───────────────────────────────
jest.mock('aws-sdk', () => ({
  // aws.js does `aws.config = { ... }` – the property must be writable
  config: {},
  S3: jest.fn().mockImplementation(() => ({
    getSignedUrl: jest.fn(),
    putObject: jest.fn(),
    getObject: jest.fn(),
  })),
  SNS: jest.fn().mockImplementation(() => ({
    setSMSAttributes: jest.fn(),
    publish: jest.fn(),
  })),
}));

// Suppress logger noise
jest.mock('../../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
}));

// Env vars consumed at module-load time by aws.js
process.env.AwsS3Bucket = 'test-bucket';
process.env.AwsCloudFront = 'cdn.test.example.com';
process.env.PreSignedUrlExpiration = '3600';
process.env.SnsAwsRegion = 'us-east-1';

const awsUtils = require('../../helper/aws');

// ─── getS3Url() ─────────────────────────────────────────────────────────────

describe('awsUtils.getS3Url()', () => {
  it('returns an https URL containing the bucket name and key', () => {
    const url = awsUtils.getS3Url('folder/image.jpg');
    expect(url).toMatch(/^https:\/\//);
    expect(url).toContain('test-bucket');
    expect(url).toContain('folder/image.jpg');
  });

  it('URL format is <bucket>.s3.amazonaws.com/<key>', () => {
    const url = awsUtils.getS3Url('path/to/file.mp4');
    expect(url).toBe('https://test-bucket.s3.amazonaws.com/path/to/file.mp4');
  });
});

// ─── getCFUrl() ──────────────────────────────────────────────────────────────

describe('awsUtils.getCFUrl()', () => {
  it('returns an https URL containing the CloudFront domain and key', () => {
    const url = awsUtils.getCFUrl('videos/stream.m3u8');
    expect(url).toMatch(/^https:\/\//);
    expect(url).toContain('cdn.test.example.com');
    expect(url).toContain('videos/stream.m3u8');
  });

  it('URL format is https://<cloudfront>/<key>', () => {
    const url = awsUtils.getCFUrl('images/photo.jpg');
    expect(url).toBe('https://cdn.test.example.com/images/photo.jpg');
  });
});

// ─── getNewKey() ─────────────────────────────────────────────────────────────

describe('awsUtils.getNewKey()', () => {
  it('returns an empty object when thumbs is null', () => {
    expect(awsUtils.getNewKey('images', 'jpg', null)).toEqual({});
  });

  it('returns an empty object when thumbs array is empty', () => {
    expect(awsUtils.getNewKey('images', 'jpg', [])).toEqual({});
  });

  it('returns one entry per thumbnail with the correct prefix key', () => {
    const thumbs = [
      { prefix: 'small', width: 120, height: 120 },
      { prefix: 'large', width: 800, height: 600 },
    ];
    const result = awsUtils.getNewKey('photos', 'png', thumbs);

    expect(Object.keys(result)).toEqual(['small', 'large']);
  });

  it('each entry contains a key string, width, and height', () => {
    const thumbs = [{ prefix: 'thumb', width: 200, height: 150 }];
    const result = awsUtils.getNewKey('media', 'jpg', thumbs);

    expect(typeof result.thumb.key).toBe('string');
    expect(result.thumb.width).toBe(200);
    expect(result.thumb.height).toBe(150);
  });

  it('the generated key contains the prefix, a UUID, the thumb prefix, and extension', () => {
    const thumbs = [{ prefix: 'sm', width: 100, height: 100 }];
    const result = awsUtils.getNewKey('uploads', 'gif', thumbs);

    expect(result.sm.key).toMatch(/^uploads\/.+_sm\.gif$/);
  });

  it('generates unique UUIDs across two calls', () => {
    const thumbs = [{ prefix: 'sm', width: 50, height: 50 }];
    const a = awsUtils.getNewKey('img', 'jpg', thumbs);
    const b = awsUtils.getNewKey('img', 'jpg', thumbs);
    expect(a.sm.key).not.toBe(b.sm.key);
  });
});

// ─── getPreSignedURL() ───────────────────────────────────────────────────────

describe('awsUtils.getPreSignedURL()', () => {
  it('resolves with preSignedUrl, key, and url on success', async () => {
    const s3 = awsUtils.getS3();
    s3.getSignedUrl.mockImplementation((operation, params, cb) => {
      cb(null, 'https://signed.example.com/object?signature=abc');
    });

    const result = await awsUtils.getPreSignedURL('profile-photos');

    expect(result.preSignedUrl).toBe('https://signed.example.com/object?signature=abc');
    expect(result.key).toMatch(/^profile-photos\//);
    expect(result.url).toContain('test-bucket');
    expect(result.url).toContain('profile-photos/');
  });

  it('uses putObject as the S3 operation', async () => {
    const s3 = awsUtils.getS3();
    s3.getSignedUrl.mockImplementation((operation, params, cb) => {
      cb(null, 'https://signed.example.com/obj');
    });

    await awsUtils.getPreSignedURL('avatars');

    expect(s3.getSignedUrl).toHaveBeenCalledWith(
      'putObject',
      expect.objectContaining({ Bucket: 'test-bucket' }),
      expect.any(Function)
    );
  });

  it('uses ACL public-read in the signed URL parameters', async () => {
    const s3 = awsUtils.getS3();
    s3.getSignedUrl.mockImplementation((operation, params, cb) => {
      cb(null, 'https://signed.example.com/obj');
    });

    await awsUtils.getPreSignedURL('covers');

    expect(s3.getSignedUrl).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ ACL: 'public-read' }),
      expect.any(Function)
    );
  });

  it('generates a unique key per call', async () => {
    const s3 = awsUtils.getS3();
    s3.getSignedUrl.mockImplementation((operation, params, cb) => {
      cb(null, 'https://signed.example.com/obj');
    });

    const [a, b] = await Promise.all([
      awsUtils.getPreSignedURL('media'),
      awsUtils.getPreSignedURL('media'),
    ]);
    expect(a.key).not.toBe(b.key);
  });
});

// ─── publishSnsSMS() ─────────────────────────────────────────────────────────

describe('awsUtils.publishSnsSMS()', () => {
  // The SNS instance is private inside the module. We access its mock
  // through the aws-sdk mock's constructor call record.
  let snsInstance;

  beforeAll(() => {
    const aws = require('aws-sdk');
    // The SNS constructor was called once at module load; grab that instance.
    snsInstance = aws.SNS.mock.instances[0];
  });

  beforeEach(() => {
    snsInstance.setSMSAttributes.mockReset();
    snsInstance.publish.mockReset();
  });

  it('resolves with SNS response data on success', async () => {
    snsInstance.setSMSAttributes.mockImplementation((params, cb) => cb(null, {}));
    snsInstance.publish.mockImplementation((params, cb) => cb(null, { MessageId: 'msg-1' }));

    const result = await awsUtils.publishSnsSMS('+15555550100', 'Your OTP is 123456');
    expect(result).toMatchObject({ MessageId: 'msg-1' });
  });

  it('passes the phone number and message to sns.publish', async () => {
    snsInstance.setSMSAttributes.mockImplementation((params, cb) => cb(null, {}));
    snsInstance.publish.mockImplementation((params, cb) => cb(null, { MessageId: 'msg-2' }));

    await awsUtils.publishSnsSMS('+15555550199', 'Hello');

    expect(snsInstance.publish).toHaveBeenCalledWith(
      expect.objectContaining({
        PhoneNumber: '+15555550199',
        Message: 'Hello',
      }),
      expect.any(Function)
    );
  });

  it('rejects when sns.publish returns an error', async () => {
    snsInstance.setSMSAttributes.mockImplementation((params, cb) => cb(null, {}));
    snsInstance.publish.mockImplementation((params, cb) =>
      cb(new Error('SNS error'), null)
    );

    await expect(awsUtils.publishSnsSMS('+15555550100', 'OTP')).rejects.toThrow('SNS error');
  });
});
