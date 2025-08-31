# TiqTaqToe 

A sample web app to play Tic Tac Toe against the computer. The application requires minimum JDK 24 to run locally.

## Technologies

This application has several components:

* Running on JDK 24+ and built with Maven.
* Setup built with Spring Boot (v3.5.5), persistency layer with JPA and H2 database, UI with Thymeleaf with Bootstrap
* Containerized with Dockerfile and deployed with Docker Compose.

|           UI Component      |                   Link                             |
|-----------------------------|----------------------------------------------------|
| Header                      | https://getbootstrap.com/docs/5.3/examples/headers/|
| Footer                      | https://getbootstrap.com/docs/5.3/examples/footers/|
| Sign In and Register        | https://getbootstrap.com/docs/5.3/examples/sign-in/|


## How to enable SSL

The application can start an HTTPS server on 8443 by having the following configuration in [`application.properties`](src/main/resources/application.properties)

```properties
server.ssl.bundle=game
spring.ssl.bundle.jks.game.keystore.location=current/server.p12
spring.ssl.bundle.jks.game.keystore.password=changeit
spring.ssl.bundle.jks.game.keystore.type=PKCS12
spring.ssl.bundle.jks.game.key.alias=server
spring.ssl.bundle.jks.game.key.password=changeit
```

In order to build an example keystore and truststore, run the script from [current/setup-mtls.sh](current/setup-mtls.sh)

For mTLS, add the following lines to the existing bundle:

```properties
server.ssl.bundle=game
server.ssl.client-auth=need
spring.ssl.bundle.jks.game.truststore.location=current/client.p12
spring.ssl.bundle.jks.game.truststore.password=changeit
```

**IMPORTANT** For demo purposes, `application.properties` contains the passwords in clear. 
For production environments you must consider encrypting your passwords.

## How to play

You can start the application locally
from your IDE or by running the following command in a terminal window:

```
./mvnw spring-boot:run
```

When accessing the application on https://localhost:8443, you will be asked to sign in to play. If you didn't register, 
you can do so by clicking [the register link](https://localhost:8443/register). 
If there is an user already registered with a chosen username, please select a different one.

Once you register, login with your chosen username and password to play. Have fun!

## How to deploy

You can deploy the application locally via Docker Compose. First build the application using:

```
./mvnw verify
```

If you wish to deploy in other environments, you can always build and push a docker image using:

```
docker buildx build --platform=linux/amd64  --tag <registry>/<username>/tictactoe:1.0 . --no-cache
```