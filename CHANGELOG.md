# Change Log
All notable changes to this project will be documented in this file.
`MongoKitten` adheres to [Semantic Versioning](http://semver.org/).

## [3.1.0-Beta](https://github.com/OpenKitten/MongoKitten/tree/mongokitten31)
##### Enhancements
* Geo2Sphere Index
* Geospatial Query Operators
* Geospatial Aggregation Operator
* Better GridFS support
* `db.createCollection` now accepts a `Query` as validator
* Updated the batchSize of read queries to 100 by default

## [3.0.5](https://github.com/OpenKitten/MongoKitten/releases/tag/3.0.5)
##### Enhancements
* StaticString support for ~10% more performance

## [3.0.4](https://github.com/OpenKitten/MongoKitten/releases/tag/3.0.4)
##### Bug Fixes
* Fixed the batch size not being used properly

## [3.0.3](https://github.com/OpenKitten/MongoKitten/releases/tag/3.0.3)
##### Bug Fixes
* Fix findAndModify not returning any Value

## [3.0.2](https://github.com/OpenKitten/MongoKitten/releases/tag/3.0.2)
##### Bug Fixes
* Fixed insert not throwing write error exceptions

## [3.0.1](https://github.com/OpenKitten/MongoKitten/releases/tag/3.0.1)
##### Bug Fixes
* Automatic reconnection

## [3.0.0] (https://github.com/OpenKitten/MongoKitten/releases/tag/3.0.0)
##### Enhancements
* Support for SSL
* Support for Replica Sets
* Support for Sharded Databases
* Documentation (can be found in the README)
* Better connection pool
* Better aggregate API
* Reworked underlying BSON Library