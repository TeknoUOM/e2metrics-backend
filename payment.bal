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
                returnData={
                    status:200
                };
                return returnData;
        } on fail var err {
            return err;
        }
        
};

public function getUserPayments(string userId) returns PaymentInDB[]|error {
    PaymentInDB[] responses = [];
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
    do {
        
        stream<PaymentInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Payment WHERE UserID = ${userId}`);
        check from PaymentInDB payment in resultStream
            do {
                responses.push(payment);
            };
        check resultStream.close();
        return responses;
    } on fail error e {
        return e;
    }
        
};