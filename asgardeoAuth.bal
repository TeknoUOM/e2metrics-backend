import ballerina/http;
import ballerina/mime;

http:Client asgardeoClient = check new ("https://api.asgardeo.io", httpVersion = http:HTTP_1_1);

function getAuthToken(string scope) returns string|error {

    string clientID = "2TvAgxdthV3fBr4bAWFvPqkwd54a";
    string clientSecrat = "lMrOSM2dg1yLIi4FL08QBIoAd_Ma";

    string combineKey = clientID + ":" + clientSecrat;

    byte[] keyInBytes = combineKey.toBytes();
    string encodedString = keyInBytes.toBase64();

    string accessToken;

    do {
        json response = check asgardeoClient->post("/t/tekno/oauth2/token",
        {
            "scope": scope,
            "grant_type": "client_credentials"
        },
        {
            "Authorization": "Basic " + encodedString
        },
            mime:APPLICATION_FORM_URLENCODED
        );

        accessToken = check response.access_token;
        return accessToken;
    } on fail var err {
        return err;
    }
}
