const branch = require('node-branch-io');

const branchUtils = {};

branchUtils.link = (feedId, title, desc, image) => {
  return branch.link.create(process.env.BranchKey, {
    channel: 'facebook',
    data: {
      feedId,
      $og_title: title,
      $og_description: desc,
      $og_image_url: image,
    },
  });
};

module.exports = branchUtils;

