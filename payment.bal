import ballerina/sql;
import ballerinax/mysql;
type PaymentInDB record {
    string 'timestamp;
    string 'id;
    string 'userId;
    string 'amountValue;
    string 'amountCurrencyCode;
    string 'subscription;
};
public function savePayment(string timestamp,string id,string userId,float amountValue,string amountCurrencyCode,string subscription) returns json|error {
        json returnData = {};
        mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
        do {
            _ = check dbClient->execute(`
	            INSERT INTO Payment
                VALUES (${timestamp}, ${id},${userId},${amountValue},${amountCurrencyCode},${subscription})`);
        sql:Error? close = dbClient.close();
                returnData={
                    status:200
                };
                return returnData;
        } on fail var err {
            sql:Error? close = dbClient.close();
            return err;
        }
        
};

public function getUserPayments(string userId) returns PaymentInDB[]|error {
    PaymentInDB[] responses = [];
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
    do {
        
        stream<PaymentInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Payment WHERE UserID = ${userId}`);
        sql:Error? close = dbClient.close();
        check from PaymentInDB payment in resultStream
            do {
                responses.push(payment);
            };
        check resultStream.close();
        return responses;
    } on fail error e {
        sql:Error? close = dbClient.close();
        return e;
    }
        
};