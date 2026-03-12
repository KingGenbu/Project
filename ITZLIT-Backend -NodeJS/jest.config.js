'use strict';

module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js'],
  collectCoverageFrom: [
    'helper/**/*.js',
    'middleware.js',
    'modules/**/*.js',
    '!node_modules/**',
  ],
  coverageThreshold: {
    global: {
      lines: 20,
    },
  },
};
