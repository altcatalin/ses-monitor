'use strict';

class Plugin {
    constructor(serverless, options) {
        this.serverless = serverless;
        this.options = options;

        this.awsProvider = this.serverless.getProvider('aws');

        this.hooks = {
            'after:package:initialize': this.nameCompliance.bind(this),
        };
    }

    nameCompliance() {
        Object.keys(this.serverless.service.resources.Resources).forEach((name) => {

            // S3 Bucket Name
            if (this.serverless.service.resources.Resources[name].Type === 'AWS::S3::Bucket') {
                this.serverless.service.resources.Resources[name].Properties.BucketName = this.serverless.service.resources.Resources[name].Properties.BucketName.toLowerCase();
            }

            // Cognito Identity Provider Name
            if (this.serverless.service.resources.Resources[name].Type === 'AWS::Cognito::IdentityPool') {
                let re = /[^\w]/gi;
                this.serverless.service.resources.Resources[name].Properties.IdentityPoolName = this.serverless.service.resources.Resources[name].Properties.IdentityPoolName.replace(re, '');
            }
        });
    }
}

module.exports = Plugin;