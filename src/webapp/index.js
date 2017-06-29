'use strict';

require('./css/style.css');
require('./index.html');

const AWSCognito = require('amazon-cognito-identity-js');
const AWS = require('aws-sdk');
const Elm = require('./elm/Main.elm');
const config = require('./config.js');

const cognitoUserPool = new AWSCognito.CognitoUserPool({
  UserPoolId : config.aws.poolId,
  ClientId : config.aws.clientId
});

let user = cognitoUserPool.getCurrentUser();
let app;

Promise
  .resolve()
  .then(init)
  .then(initApp)
  .catch(initApp);

function init() {
  if (user !== null) {
    return Promise
      .resolve()
      .then(getSession)
      .then(refreshCredentials);
  } else {
    return Promise.resolve();
  }
}

function initApp(initErr) {
  const params = {
    username: (user !== null) ? user.getUsername() : null
  };

  app = Elm.Main.embed(document.getElementById('ses-monitor-webapp'), params);

  if (initErr) {
    app.ports.loginErrorPort.send(initErr.message);
  }

  app.ports.loginPort.subscribe(login);
  app.ports.logoutPort.subscribe(logout);
  app.ports.suppressionPort.subscribe(getSuppressedRecipients);
}

function login(data) {
  user = new AWSCognito.CognitoUser({
    Username : data.username,
    Pool : cognitoUserPool
  });

  const authenticationDetails = new AWSCognito.AuthenticationDetails({
    Username : data.username,
    Password : data.password
  });

  return Promise
    .resolve(authenticationDetails)
    .then(authenticate)
    .then(refreshCredentials)
    .then(() => {
      app.ports.loginSuccessPort.send(user.getUsername());
    })
    .catch((err) => {
      app.ports.loginErrorPort.send(err.message);
    });
}

function logout() {
  if (user !== null) {
    user.signOut();
  }
}

function getSuppressedRecipients() {
  const dynamodb = new AWS.DynamoDB();

  dynamodb.query({
    TableName: config.aws.dynamodb.suppression,
    IndexName: 'timestamp',
    ExpressionAttributeValues: {
      ":s": {
        N: "1"
      }
    },
    KeyConditionExpression: "s = :s",
    ScanIndexForward: false
  })
  .promise()
  .then((data) => {
    const items = data.Items.map(function(item) {
      let newItem = {};

      Object.keys(item).forEach(function(key) {
        newItem[key] = item[key][Object.keys(item[key])[0]];
      });

      return newItem;
    });

    app.ports.suppressionSuccessPort.send(items);
  })
  .catch((err) => {
    app.ports.suppressionErrorPort.send(err.message);
  });
}

function authenticate(authenticationDetails) {
  return new Promise((resolve, reject) => {
    user.authenticateUser(authenticationDetails, {
      onSuccess: resolve,
      onFailure: reject
    })
  });
}

function getSession() {
  return new Promise(function(resolve, reject) {
    user.getSession(function(err, session) {
      if (err) reject(err);
      else resolve(session);
    });
  })
}

function refreshCredentials(session) {
  const idpEndpoint = `cognito-idp.${config.aws.region}.amazonaws.com/${config.aws.poolId}`;

  AWS.config.region = config.aws.region;
  AWS.config.credentials = new AWS.CognitoIdentityCredentials({
    IdentityPoolId : config.aws.identityPoolId,
    Logins : {
      [idpEndpoint] : session.getIdToken().getJwtToken()
    }
  });

  return new Promise(function(resolve, reject) {
    AWS.config.credentials.refresh(function(err) {
      if (err) reject(err);
      else resolve();
    });
  });
}
