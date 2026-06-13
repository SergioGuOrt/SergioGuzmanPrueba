// Services/Persistence/ViewedEpisode+CoreDataProperties.swift
//  SergioGuzmanPrueba
//
//  Propiedades de la entidad ViewedEpisode.
//  Refleja exactamente los atributos del modelo .xcdatamodel.

import Foundation
import CoreData

extension ViewedEpisode {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ViewedEpisode> {
        return NSFetchRequest<ViewedEpisode>(entityName: "ViewedEpisode")
    }

    // MARK: - Attributes

    @NSManaged public var characterId: Int32
    @NSManaged public var episodeId:   Int32
    @NSManaged public var episodeName: String
    @NSManaged public var episodeCode: String
    @NSManaged public var isViewed:    Bool
    @NSManaged public var viewedAt:    Date
}
