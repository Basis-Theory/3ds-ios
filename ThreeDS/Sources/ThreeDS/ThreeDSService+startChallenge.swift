//
//  ThreeDSService+startChallenge.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//
import Foundation
import Ravelin3DS

@available(iOS 15.0, *)
extension ThreeDSService {
    public func startChallenge(
        sessionId: String, viewController: UIViewController,
        onCompleted: @escaping (ChallengeResponse) -> Void,
        onFailure: @escaping (ChallengeResponse) -> Void
    ) async throws {
        let authenticationResponse = try await authenticateSession(sessionId: sessionId)

        do {
            if authenticationResponse.authenticationStatus == "challenge" {
                let challengeParams = ChallengeParameters()
                challengeParams.set3DSServerTransactionID(sessionId)
                challengeParams.setAcsTransactionID(authenticationResponse.acsTransactionId)
                challengeParams.setAcsRefNumber(authenticationResponse.acsReferenceNumber)
                challengeParams.setAcsSignedContent(authenticationResponse.acsSignedContent ?? "")
                challengeParams.setThreeDSRequestorAppURL(
                    "https://www.ravelin.com/?transID=\(try self.transaction.getAuthenticationRequestParameters().getSDKTransactionID())"
                )

                challengeReceiver = ChallengeHandler(
                    sessionId: sessionId, authenticationResponse: authenticationResponse,
                    onCompleted: onCompleted, onFailure: onFailure, transaction: transaction)

                try self.transaction.doChallenge(
                    challengeParameters: challengeParams,
                    challengeStatusReceiver: challengeReceiver,
                    timeOut: 5,
                    challengeView: ChallengeViewImplementation(viewController: viewController))
            } else {
                onCompleted(
                    ChallengeResponse(
                        id: sessionId,
                        status: authenticationResponse.authenticationStatus,  // Added missing comma
                        details: authenticationResponse.authenticationStatusReason
                    ))
            }
        } catch {
            onFailure(
                ChallengeResponse(
                    id: sessionId,
                    status: authenticationResponse.authenticationStatus,  // Added missing comma
                    details: error.localizedDescription))
        }
    }

    func authenticateSession(sessionId: String) async throws -> AuthenticationResponse {
        let jsonBody: [String: String] = [
            "sessionId": sessionId
        ]

        let requestBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        guard let authenticationEndpoint = URL(string: self.authenticationEndpoint) else {
            throw ThreeDSServiceError.invalidURL
        }

        return try await makeRequest(
            url: authenticationEndpoint,
            method: "POST",
            body: requestBody,
            expectedStatusCodes: [200]
        )
    }
}
