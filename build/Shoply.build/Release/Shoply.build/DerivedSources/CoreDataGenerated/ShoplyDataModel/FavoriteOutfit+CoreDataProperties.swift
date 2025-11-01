//
//  FavoriteOutfit+CoreDataProperties.swift
//  
//
//  Created by William on 01/11/2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias FavoriteOutfitCoreDataPropertiesSet = NSSet

extension FavoriteOutfit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteOutfit> {
        return NSFetchRequest<FavoriteOutfit>(entityName: "FavoriteOutfit")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isSynced: Bool

}

extension FavoriteOutfit : Identifiable {

}
