'use strict';

jest.mock('../../modules/connection/connectionModel');

const Connection = require('../../modules/connection/connectionModel');
const connectionUtils = require('../../modules/connection/connectionUtils');

const FAKE_USER = '507f1f77bcf86cd799439011';
const FAKE_USER_B = '507f1f77bcf86cd799439022';

beforeEach(() => {
  jest.clearAllMocks();
  Connection.aggregate = jest.fn();
});

// ─── getFollowers() ───────────────────────────────────────────────────────────

describe('connectionUtils.getFollowers()', () => {
  it('resolves with { users, devices } when followers exist', async () => {
    Connection.aggregate.mockResolvedValue([
      {
        follower: { _id: FAKE_USER_B, fullName: 'Bob' },
        devices: [{ deviceToken: 'tok-bob', notificationPref: true }],
      },
    ]);

    const result = await connectionUtils.getFollowers(FAKE_USER);

    expect(result).toHaveProperty('users');
    expect(result).toHaveProperty('devices');
    expect(result.users).toHaveLength(1);
    expect(result.users[0].fullName).toBe('Bob');
    expect(result.devices).toContain('tok-bob');
  });

  it('resolves with empty arrays when there are no followers', async () => {
    Connection.aggregate.mockResolvedValue([]);

    const result = await connectionUtils.getFollowers(FAKE_USER);

    expect(result.users).toHaveLength(0);
    expect(result.devices).toHaveLength(0);
  });

  it('only includes device tokens where notificationPref is true', async () => {
    Connection.aggregate.mockResolvedValue([
      {
        follower: { _id: FAKE_USER_B },
        devices: [
          { deviceToken: 'enabled-tok', notificationPref: true },
          { deviceToken: 'disabled-tok', notificationPref: false },
          { deviceToken: 'missing-pref-tok' }, // no notificationPref key
        ],
      },
    ]);

    const { devices } = await connectionUtils.getFollowers(FAKE_USER);

    expect(devices).toContain('enabled-tok');
    expect(devices).not.toContain('disabled-tok');
    expect(devices).not.toContain('missing-pref-tok');
  });

  it('collects device tokens from multiple followers', async () => {
    Connection.aggregate.mockResolvedValue([
      {
        follower: { _id: 'follower-a' },
        devices: [{ deviceToken: 'tok-a', notificationPref: true }],
      },
      {
        follower: { _id: 'follower-b' },
        devices: [{ deviceToken: 'tok-b', notificationPref: true }],
      },
    ]);

    const { devices } = await connectionUtils.getFollowers(FAKE_USER);

    expect(devices).toEqual(expect.arrayContaining(['tok-a', 'tok-b']));
    expect(devices).toHaveLength(2);
  });

  it('handles followers with no devices array gracefully', async () => {
    Connection.aggregate.mockResolvedValue([
      { follower: { _id: FAKE_USER_B }, devices: [] },
    ]);

    const { devices } = await connectionUtils.getFollowers(FAKE_USER);

    expect(devices).toHaveLength(0);
  });

  // ── whitelist filtering ────────────────────────────────────────────────────

  it('passes no follower filter when whitelist is empty', async () => {
    Connection.aggregate.mockResolvedValue([]);

    await connectionUtils.getFollowers(FAKE_USER, []);

    const matchStage = Connection.aggregate.mock.calls[0][0][0].$match;
    expect(matchStage).toEqual({ followee: FAKE_USER });
    expect(matchStage).not.toHaveProperty('follower');
  });

  it('adds a $in follower filter when a whitelist is provided', async () => {
    Connection.aggregate.mockResolvedValue([]);

    const whitelist = [FAKE_USER_B];
    await connectionUtils.getFollowers(FAKE_USER, whitelist);

    const matchStage = Connection.aggregate.mock.calls[0][0][0].$match;
    expect(matchStage.follower).toEqual({ $in: whitelist });
  });

  it('rejects when Connection.aggregate rejects', async () => {
    Connection.aggregate.mockRejectedValue(new Error('DB error'));

    await expect(connectionUtils.getFollowers(FAKE_USER)).rejects.toThrow('DB error');
  });
});
