// The MIT License (MIT)

// Copyright (c) 2016 Ian Spence

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

class Bonjour: NSObject, NetServiceBrowserDelegate {
    var timeout: TimeInterval = 1.0
    var serviceFoundClosure: (([NetService]) -> Void)!
    var domainFoundClosure: (([String]) -> Void)!

    // Source: https://developer.apple.com/library/mac/qa/qa1312/_index.html
    struct Services {
        // test
        static let Test: String = "_test._tcp."
        // airplay
        static let AirPlay: String = "_airplay._tcp."
    }
    static let LocalDomain: String = "local."

    let serviceBrowser: NetServiceBrowser = NetServiceBrowser()
    var services = [NetService]()
    var domains = [String]()
    var isSearching: Bool = false
    var serviceTimeout: Timer = Timer()
    var domainTimeout: Timer = Timer()

    /// Find all servies matching the given identifer in the given domain
    ///
    /// Calls servicesFound: with any services found
    /// If no services were found, servicesFound: is called with an empty array
    ///
    /// **Please Note:** Only one search can run at a time.
    ///
    /// - parameters:
    ///   - identifier: The service identifier. You may use Bonjour.Services for common services
    ///   - domain: The domain name for the service.  You may use Bonjour.LocalDomain
    /// - returns: True if the search was started, false if a search is already running
    func findService(_ identifier: String, domain: String, found: @escaping ([NetService]) -> Void) -> Bool {
        if !isSearching {
            serviceBrowser.delegate = self
            serviceTimeout = Timer.scheduledTimer(
                timeInterval: self.timeout,
                target: self,
                selector: #selector(Bonjour.noServicesFound),
                userInfo: nil,
                repeats: false)
            serviceFoundClosure = found
            serviceBrowser.searchForServices(ofType: identifier, inDomain: domain)
            print("starting search")
            isSearching = true
            return true
        }
        return false
    }

    /// Find all of the browsable domains
    ///
    /// Calls domainsFound: with any domains found
    /// If no domains were found, domainsFound: is called with an empty array
    ///
    /// **Please Note:** Only one search can run at a time.
    ///
    /// - returns: True if the search was started, false if a search is already running
    func findDomains(_ found: @escaping ([String]) -> Void) -> Bool {
        if !isSearching {
            serviceBrowser.delegate = self
            domainTimeout = Timer.scheduledTimer(
                timeInterval: self.timeout,
                target: self,
                selector: #selector(Bonjour.noDomainsFound),
                userInfo: nil,
                repeats: false)
            serviceBrowser.searchForBrowsableDomains()
            domainFoundClosure = found
            isSearching = true
            return true
        }
        return false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService,
                           moreComing: Bool) {
        serviceTimeout.invalidate()
        services.append(service)
        if !moreComing {
            serviceFoundClosure(services)
            serviceBrowser.stop()
            isSearching = false
        }
    }

    @objc func noServicesFound() {
        serviceFoundClosure([])
        serviceBrowser.stop()
        isSearching = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String,
                           moreComing: Bool) {
        domainTimeout.invalidate()
        domains.append(domainString)
        if !moreComing {
            domainFoundClosure(domains)
            serviceBrowser.stop()
            isSearching = false
        }
    }

    @objc func noDomainsFound() {
        domainFoundClosure([])
        serviceBrowser.stop()
        isSearching = false
    }
}
