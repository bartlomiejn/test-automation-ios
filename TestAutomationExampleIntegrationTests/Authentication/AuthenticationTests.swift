//
//  AuthenticationTests.swift
//  TestAutomationExampleIntegrationTests
//
//  Created by Bartłomiej Nowak on 22.09.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import XCTest

class AuthenticationTests: XCTestCase
{
    private enum Constant
    {
        static let success = "success"
        static let failure = "failure"
    }
    private enum Credentials
    {
        static let username = "testauthexample"
        static let password = "testauthexample123"
    }
    
    private var app: XCUIApplication!
    
    override func setUp()
    {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    override func tearDown()
    {
        app.terminate()
        app = nil
        super.tearDown()
    }
    
    func test_GivenUnauthorized_WhenSignIn_ThenStayOnAuthenticationPageAndShowError()
    {
        app.launchForIntegrationTesting(withAuthenticationStub: "unauthorized")
        AuthenticationPage(assertingExistenceWithApp: app)?
            .signInWithCredentials(username: Credentials.password, password: Credentials.password)
            .waitForErrorLabelAssertingExistence(timeout: 5.0)
    }
}
