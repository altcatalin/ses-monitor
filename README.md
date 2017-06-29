# SES Monitor

Simple SPA build with [Elm](http://elm-lang.org/) on a [Serverless](https://serverless.com/) architecture to monitor [AWS SES](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notifications.html) Suppression List

Architecture diagram ![Architecture diagram](https://raw.github.com/altcatalin/ses-monitor/master/architecture_diagram.png)

## Prerequisites

* [AWS account](https://aws.amazon.com/)
* [AWS SES verified email addess or domain](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-addresses-and-domains.html)
* [aws-cli](https://aws.amazon.com/cli/)
* [Yarn](https://yarnpkg.com/en/docs/install)
* [Node.js](https://nodejs.org/en/)
* [Serverless](https://serverless.com/framework/docs/getting-started/)
* [Elm](https://guide.elm-lang.org/install.html)

## Deployment

1. prefix functions, services and resources names to prevent collision on AWS 
    
    edit `serverless.yml`
    
    ```
    custom:
      prefix: ""
    ```
    
2. deploy stack on AWS: `serverless deploy -v`
3. configure [AWS SES Bounce Notifications](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notifications-via-sns.html) to send notifications with original headers to the SNS Topic from step 2.
3. copy `src/webapp/config.template.js` to `src/webapp/config.js` and fill with the stack outputs values from step 2.
3. install SPA dependencies: `yarn install && elm package install`
6. build SPA: `yarn build`
7. deploy SPA to S3:
    
    ```
    aws s3 sync dist s3://S3_BUCKET
    ```

8. sign up a Cognito user

    ```
    aws cognito-idp sign-up \
       --client-id COGNITO_APP_CLIENT_ID \
       --username USERNAME \
       --password PASSWORD
    ```

9. confirm Cognito user sign up
 
    ```
    aws cognito-idp admin-confirm-sign-up \
      --user-pool-id COGNITO_POOL_ID \
      --username USERNAME
    ```
    