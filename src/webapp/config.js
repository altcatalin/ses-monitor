'use strict';

var config = {};

config.aws = {};

config.aws.region = 'eu-west-1';
config.aws.poolId = 'eu-west-1_rG0fwiVRm';
config.aws.clientId = '5vt2dqf9r74jgb9qov5q4b13d0';
config.aws.identityPoolId = 'eu-west-1:1f7ee029-81e8-40c4-9463-d88dcfa39830';

config.aws.dynamodb = {};
config.aws.dynamodb.suppression = 'Ses-Monitor-Suppression-production';

module.exports = config;
