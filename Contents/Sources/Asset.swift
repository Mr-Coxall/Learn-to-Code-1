//
//  Asset.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//

import SceneKit

enum AssetLoadingError: Error {
    case invalidFileName(String)
}

enum Asset {
    enum Directory {
        static let characters = "Characters.scnassets/"
        static let worldResources = "WorldResources.scnassets/"
        
        case music
        case images
        case scenes
        case textures
        case props
        case items
        case templates
        
        case item(WorldNodeIdentifier)
        case actor(ActorType)
        case custom(String)
        
        var path: String {
            switch self {
            case .music, .images:
                return directoryName()!
                
            case .scenes, .textures, .props, .items, .templates:
                return Directory.worldResources + directoryName()!
            
            case let .item(identifier):
                return Directory.itemPath(for: identifier)
                
            case let .actor(type):
                return Directory.actorPath(for: type)
                
            case let .custom(path):
                return path
            }
        }
        
        /// Returns the name of the directory.
        func directoryName() -> String? {
            switch self {
            case .scenes: return "_Scenes/"
            case .textures: return "textures/"
            case .music: return "Audio/"
            case .images: return "Images/"
            case .props: return "props/"
            case .items: return "items/"
            case .templates: return "Custom/"
            default: return nil
            }
        }
        
        static func itemPath(for id: WorldNodeIdentifier) -> String {
            switch id {
            case .block,
                .stair:         return worldResources + "blocks/"
            case .water:        return worldResources + "barrier/"
            case .startMarker,
                 .wall:         return props.path
            case .item:         return items.path + "Gem/"
            case .switch:       return items.path + "Switch/"
            case .portal:       return items.path + "Portal/"
            case .platformLock: return items.path + "Lock/"
            case .platform:     return items.path + "Platform/"
            case .randomNode:   return items.path + "RandomItems/"
            case .actor:
                fatalError("There are multiple actor directories, use `Directory.actor(for:)` instead.")
            }
        }
        
        static func actorPath(for type: ActorType) -> String {
            let dir: String
            switch type {
            case .byte: dir = "Byte"
            case .blu: dir = "Blu"
            case .hopper: dir = "Hopper"
            case .expert: dir = "Expert"
            }
            return characters + dir + "/"
        }
    }
    
    static func animations(for group: EventGroup, in directory: Directory) -> [CAAnimation] {
        return group.identifiers.flatMap { name in
            guard let animation = animation(named: name, in: directory) else {
                log(message: "Failed to load '\(directory.path)\(name).dae' animation.")
                return nil
            }
            return animation
        }
    }
    
    static func animation(named: String, in directory: Directory) -> CAAnimation? {
        return CAAnimation.animation(fromResource: directory.path + named)
    }
    
    static func sounds(for group: EventGroup, in directory: Directory) -> [SCNAudioSource] {
        return group.identifiers.flatMap { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: directory.path) else {
                log(message: "Failed to load '\(directory.path)\(group).m4a' audio.")
                return nil
            }
            
            return SCNAudioSource(url: url)
        }
    }
    
    static func backgroundAudio(named name: String) -> SCNAudioSource? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: Directory.music.path) else { return nil }
        
        return SCNAudioSource(url: url)
    }
    
    static func neutralPose(in directory: Directory, fileExtension: String = "dae") -> SCNNode? {
        return node(named: "NeutralPose", in: directory, fileExtension: fileExtension)
    }
    
    static func node(named name: String, in directory: Directory, fileExtension: String = "dae") -> SCNNode? {
        let path = directory.path + name
        guard let url = Bundle.main.url(forResource: path, withExtension: fileExtension) else {
            log(message: "Failed to create url for '\(directory.path)\(name).\(fileExtension)'.")
            return nil
        }
        
        do {
            let scene: SCNScene
            scene = try SCNScene(url: url, options: [:])
            return scene.rootNode.childNodes[0]
        }
        catch {
            log(message: "Failed to find node at: '\(directory.path)\(name).\(fileExtension)'.")
            return nil
        }
    }
    
    static func map(named name: String) -> SCNScene {
        let dir = Directory.scenes.path
        guard let scene = SCNScene(named: name, inDirectory: dir, options: [:]) else {
            fatalError("Failed to load scene \(name).")
        }
        return scene
    }
    
    static func texture(named: String, fileExtension: String = "png") -> URL? {
        let basePath = Directory.textures.path
        return Bundle.main.url(forResource: basePath + named, withExtension: fileExtension)
    }
    
    #if os(iOS)
    static func image(named: String) -> UIImage? {
        let basePath = Directory.images.path
        return UIImage(named: basePath + named)
    }
    #endif
}