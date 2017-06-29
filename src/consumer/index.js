const aws = require('aws-sdk');

exports.handler = (event, context, callback) => {
  const sqs = new aws.SQS();
  const dynamo = new aws.DynamoDB();
  const queueUrl = process.env.QUEUE_URL || '';
  const tableName = process.env.TABLE_NAME || '';
  const sqsMaxNumberOfMessages = 10;
  const sqsWaitTimeSeconds = 5;
  const minimumTimeToRestartInMillis = 5000;

  Promise
    .resolve()
    .then(() => {
      (function sqsBatchProcessing() {
        return sqs
          .receiveMessage({
            QueueUrl: queueUrl,
            MaxNumberOfMessages: sqsMaxNumberOfMessages,
            WaitTimeSeconds: sqsWaitTimeSeconds,
          })
          .promise()
          .then((data) => {
            if (data.Messages) {
              return Promise
                .all(data.Messages.map((message) => {
                  const notification = JSON.parse(message.Body);
                  const notificationMessage = JSON.parse(notification.Message);

                  if (notificationMessage.notificationType === 'Bounce' && notificationMessage.bounce.bounceSubType === 'Suppressed') {
                    return dynamo
                      .putItem({
                        TableName: tableName,
                        Item: {
                          r: { S: notificationMessage.mail.commonHeaders.to[0] },
                          m: { S: notificationMessage.mail.messageId },
                          t: { S: notificationMessage.mail.timestamp },
                          s: { N: 1 },
                        },
                        ConditionExpression: 'attribute_not_exists(r)',
                      })
                      .promise()
                      .catch((err) => {
                        if (err.code !== 'ConditionalCheckFailedException') {
                          return err;
                        }

                        return Promise.resolve();
                      })
                      .then(() => {
                        return sqs
                          .deleteMessage({
                            QueueUrl: queueUrl,
                            ReceiptHandle: message.ReceiptHandle,
                          })
                          .promise();
                      });
                  }

                  return Promise.resolve();
                }))
                .then(() => {
                  if (data.Messages.length === sqsMaxNumberOfMessages && context.getRemainingTimeInMillis() >= minimumTimeToRestartInMillis) {
                    return sqsBatchProcessing();
                  }

                  return Promise.resolve();
                });
            }

            return Promise.resolve();
          });
      }());
    })
    .then(callback)
    .catch(callback);
};
