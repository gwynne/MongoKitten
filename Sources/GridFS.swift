//
//  GridFS.swift
//  MongoKitten
//
//  Created by Joannis Orlandos on 22/03/16.
//  Copyright © 2016 PlanTeam. All rights reserved.
//

import CryptoSwift
import BSON
import Foundation

public class GridFS {
    private let files: Collection
    private let chunks: Collection
    
    public init(database: Database, bucketName: String = "fs") {
        files = database["\(bucketName).files"]
        chunks = database["\(bucketName).chunks"]
        
        do {
            try chunks.createIndex([(key: "files_id", asc: true), (key: "n", asc: true)], name: "chunksindex", partialFilterExpression: nil, buildInBackground: true, unique: true)
        } catch {}
        
        do {
            try files.createIndex([(key: "filename", asc: true), (key: "uploadDate", asc: true)], name: "filesindex", partialFilterExpression: nil, buildInBackground: true, unique: false)
        } catch {}
    }
    
    public func getFileCursor(fileID: ObjectId) throws -> Cursor<Document> {
        return try chunks.find(["files_id": fileID], sort: ["n": 1], projection: ["data": 1])
    }
    
    public func findFiles(id: ObjectId? = nil, md5: String? = nil, filename: String? = nil) throws -> Cursor<GridFSFile> {
        var filter = *[]
        
        if let id = id {
            filter += ["_id": id]
        }
        
        if let md5 = md5 {
            filter += ["md5": md5]
        }
        
        if let filename = filename {
            filter += ["filename": filename]
        }
        
        let cursor = try files.find(filter)
        
        let gridFSCursor: Cursor<GridFSFile> = Cursor(base: cursor, transform: { GridFSFile(document: $0, chunksCollection: self.chunks, filesCollection: self.files) })
        
        return gridFSCursor
    }
    
    public func findOneFile(id: ObjectId? = nil, md5: String? = nil, filename: String? = nil) throws -> GridFSFile? {
        var filter = *[]
        
        if let id = id {
            filter += ["_id": id]
        }
        
        if let md5 = md5 {
            filter += ["md5": md5]
        }
        
        if let filename = filename {
            filter += ["filename": filename]
        }
        
        guard let document = try files.findOne(filter) else {
            return nil
        }
        
        return GridFSFile(document: document, chunksCollection: chunks, filesCollection: files)
    }
    
    public func storeFile(data: NSData, filename: String? = nil, chunkSize: Int = 255000) throws -> ObjectId {
        return try self.storeFile(data.arrayOfBytes(), filename: filename, chunkSize: chunkSize)
    }
    
    public func storeFile(data: [UInt8], filename: String? = nil, chunkSize: Int = 255000) throws -> ObjectId {
        var data = data
        let id = ObjectId()
        let dataSize = data.count
        
        _ = try files.insert(["_id": id, "length": dataSize, "chunkSize": Int32(chunkSize), "uploadDate": NSDate.init(timeIntervalSinceNow: 0), "md5": data.md5().toHexString()])
        
        var n = 0
        
        while !data.isEmpty {
            let smallestMax = min(data.count, chunkSize)
            
            let chunk = Array(data[0..<smallestMax])
            
            _ = try chunks.insert(["files_id": id,
                                   "n": n,
                                   "data": Binary(data: chunk)])
            
            n += 1
            
            data.removeFirst(smallestMax)
        }
        
        return id
    }
}

public struct GridFSFile {
    public let id: ObjectId
    public let length: Int32
    public let chunkSize: Int32
    public let uploadDate: NSDate
    public let md5: String
    public let filename: String?
    public let contentType: String?
    public let aliases: [String]?
    public let metadata: BSONElement?
    
    let chunksCollection: Collection
    let filesCollection: Collection
    
    internal init?(document: Document, chunksCollection: Collection, filesCollection: Collection) {
        guard let id = document["_id"]?.objectIdValue,
            length = document["length"]?.int32Value,
            chunkSize = document["chunkSize"]?.int32Value,
            uploadDate = document["uploadDate"]?.dateValue,
            md5 = document["md5"]?.stringValue
            else {
                return nil
        }
        
        self.chunksCollection = chunksCollection
        self.filesCollection = filesCollection
        
        self.id = id
        self.length = length
        self.chunkSize = chunkSize
        self.uploadDate = uploadDate
        self.md5 = md5
        
        self.filename = document["filename"]?.stringValue
        self.contentType = document["contentType"]?.stringValue
        
        var aliases = [String]()
        
        for alias in document["aliases"]?.documentValue?.arrayValue ?? [] {
            if let alias = alias.stringValue {
                aliases.append(alias)
            }
        }
        
        self.aliases = aliases
        self.metadata = document["metadata"]
    }
    
    public func findChunks(skip: Int32 = 0, limit: Int32 = 0) throws -> Cursor<GridFSChunk> {
        let cursor = try chunksCollection.find(["files_id": id], sort: ["n": 1], skip: skip, limit: limit)
        
        return Cursor(base: cursor, transform: { GridFSChunk(document: $0, chunksCollection: self.chunksCollection, filesCollection: self.filesCollection) })
    }
}

public struct GridFSChunk {
    public let id: ObjectId
    public let filesID: ObjectId
    public let n: Int32
    public let data: Binary
    
    let chunksCollection: Collection
    let filesCollection: Collection
    
    internal init?(document: Document, chunksCollection: Collection, filesCollection: Collection) {
        guard let id = document["_id"]?.objectIdValue,
            filesID = document["files_id"]?.objectIdValue,
            n = document["n"]?.int32Value,
            data = document["data"]?.binaryValue else {
                return nil
        }
        
        self.chunksCollection = chunksCollection
        self.filesCollection = filesCollection
        
        self.id = id
        self.filesID = filesID
        self.n = n
        self.data = data
    }
}