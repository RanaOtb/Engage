//
//  Location.swift
//  LocationPicker
//
//  Created by Almas Sapargali on 7/29/15.
//  Copyright (c) 2015 almassapargali. All rights reserved.
//

import Foundation
import Contacts
import CoreLocation
import AddressBookUI

// class because protocol
open class Location: NSObject {
	open let name: String?
	
	// difference from placemark location is that if location was reverse geocoded,
	// then location point to user selected location
	open let location: CLLocation
	open let placemark: CLPlacemark
	
	open var address: String {
		// try to build full address first
		if let addressDic = placemark.addressDictionary {
			if let lines = addressDic["FormattedAddressLines"] as? [String] {
				return lines.joined(separator: ", ")
			} else {
				// fallback
				return ABCreateStringWithAddressDictionary(addressDic, true)
			}
		} else {
			return "\(coordinate.latitude), \(coordinate.longitude)"
		}
	}
	
	public init(name: String?, location: CLLocation? = nil, placemark: CLPlacemark) {
		self.name = name
		self.location = location ?? placemark.location!
		self.placemark = placemark
	}
}

import MapKit

extension Location: MKAnnotation {
    @objc public var coordinate: CLLocationCoordinate2D {
		return location.coordinate
	}
	
    public var title: String? {
		return name ?? address
	}
}
