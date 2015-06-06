//
//  GameScene.swift
//  Locution
//
//  Created by Chris Nevin on 22/08/2014.
//  Copyright (c) 2014 CJNevin. All rights reserved.
//

import SpriteKit
import SceneKit

class GameScene: SKScene {
    typealias Square = Locution.Board.Square
	typealias Word = Locution.Board.Word
    typealias Tile = Locution.Tile
    typealias SquareSprite = Sprites.SquareSprite
    typealias TileSprite = Sprites.TileSprite
    
    class GameState {
        class Player {
            var score = 0
            func incrementScore(value: Int) {
                score += value
                println("Add Score: \(value), new score: \(score)")
            }
        }
        
        var game: Locution
        var player: Player // Create array
        var squareSprites: [SquareSprite]
        var rackSprites: [TileSprite]
        var draggedSprite: TileSprite?
        var originalPoint: CGPoint?
        var view: SKView
		var node: SKNode
		private var mutableSquareSprites: [SquareSprite] {
			get {
				return squareSprites.filter({$0.tileSprite?.movable == true})
			}
		}
		private var immutableSquareSprites: [SquareSprite] {
			get {
				return squareSprites.filter({$0.tileSprite?.movable == false})
			}
		}
		
        init(view: SKView, node: SKNode) {
            self.game = Locution()
            self.player = Player()
            self.squareSprites = SquareSprite.createSprites(forGame: game, frame: view.frame)
            self.rackSprites = TileSprite.createRackSprites(forGame: game, frame: view.frame)
            self.view = view
            self.node = node
            self.setup(inView: view, node: node)
        }
        
        private func setup(inView view: SKView, node: SKNode) {
            for sprite in self.squareSprites {
                node.addChild(sprite)
            }
            for sprite in self.rackSprites {
                node.addChild(sprite)
            }
        }
        
        func reset(inView view: SKView, node: SKNode) {
            for sprite in self.squareSprites {
                sprite.removeFromParent()
            }
            for sprite in self.rackSprites {
                sprite.removeFromParent()
            }
            self.draggedSprite = nil
            self.originalPoint = nil
            self.squareSprites.removeAll(keepCapacity: false)
            self.rackSprites.removeAll(keepCapacity: false)
            self.game = Locution()
            self.player = Player()
            self.squareSprites = SquareSprite.createSprites(forGame: game, frame: view.frame)
            self.rackSprites = TileSprite.createRackSprites(forGame: game, frame: view.frame)
            self.view = view
            self.node = node
            self.setup(inView: view, node: node)
        }
		
		func submit() -> Bool {
			// TODO: Check that word intercepts center tile or another word
			// TODO: Ensure squares all touch, i.e. no gaps, all in the same column or row or count is exactly one (and not first word)
			let squares = mutableSquareSprites.map({$0.square!})
			let words = self.game.board.getWords(aroundSquares: squares)
			if words.count == 0 {
				return false
			}
			var sprites = [SquareSprite]()
			for word in words {
				if !word.isValidArrangement {
					println("Invalid word: \(word.word)")
					return false
				} else {
					var (valid, definition) = game.dictionary.defined(word.word)
					if valid {
						println("Valid word: \(word.word),  definition: \(definition!)")
					} else {
						println("Invalid word: \(word.word)")
						return false
					}
				}
				sprites.extend(getSquareSprites(forSquares:word.squares))
			}
			
			if game.board.words.count == 0 {
				// First play
				if words.count != 1 {
					println("Too many words")
					return false
				}
				if let word = words.first {
					// Ensure word is valid length
					if word.length < 2 {
						println("Word too short")
						return false
					}
					// Ensure word intersects center
					if !game.board.containsCenterSquare(inArray: word.squares) {
						println("Doesn't intersect center")
						return false
					}
				}
			} else {
				// Word must intersect the center tile, via another word
				var output = Set<Square>()
				for square in squares {
					game.board.getAdjacentFilledSquares(atPoint: square.point, vertically: true, horizontally: true, original: square, output: &output)
				}
				if !game.board.containsCenterSquare(inArray: Array(output)) {
					println("Doesn't intersect center")
					return false
				}
			}
			
			// Add words to board
			game.board.words.extend(words)
			
			var sum = words.map{$0.points}.reduce(0, combine: +)
			// Player used all tiles, reward them
			if mutableSquareSprites.count == 7 {
				sum += 50
			}
			player.incrementScore(sum)
			
			// Illuminate the wordss we changed
			illuminateWords([immutableSquareSprites], illuminated: false)
			illuminateWords([sprites], illuminated: true)
			
			// Remove the sprites from the rack
			for sprite in sprites {
				sprite.tileSprite?.movable = false
				if let spriteTile = sprite.tileSprite?.tile {
					rackSprites = rackSprites.filter({$0.tile != spriteTile})
					game.rack.tiles = game.rack.tiles.filter({$0 != spriteTile})
				}
				if let square = sprite.square {
					square.immutable = true
				}
			}
			for sprite in rackSprites {
				sprite.removeFromParent()
			}
			game.rack.replenish(fromBag: game.bag);
			rackSprites = TileSprite.createRackSprites(forGame: game, frame: view.frame)
			for sprite in rackSprites {
				node.addChild(sprite)
			}
			return true
        }
        
        // MARK: Private
        
        private func illuminateWords(words: [[SquareSprite]], illuminated: Bool) {
            // TODO: Do a nice animation if submission is successful
            for word in words {
                for square in word {
                    if let tile = square.tileSprite {
                        if illuminated {
                            tile.color = UIColor.whiteColor()
                        } else {
                            tile.color = tile.defaultColor
                        }
                    }
                }
            }
        }
		
		private func getSquareSprites(forSquares squares: [Square]) -> [SquareSprite] {
			var sprites = [SquareSprite]()
			for sprite in squareSprites {
				if let square = sprite.square {
					if contains(squares, square) {
						sprites.append(sprite)
					}
				}
			}
			return sprites
		}
    }
    
    var gameState: GameState?
    
    func newGame() {
        if let gameState = self.gameState {
            gameState.reset(inView: view!, node: self)
        } else {
            self.gameState = GameState(view:view!, node:self)
        }
    }
    
    override func didMoveToView(view: SKView) {
        self.newGame()
        
        var submit = SKLabelNode(text: "Submit")
        submit.position = view.center
        submit.position.y -= 100
        self.addChild(submit)
    }
	
	
	// MARK:- Touches
	
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		if let point = (touches.first as? UITouch)?.locationInNode(self) {
            for child in self.children {
                if let sprite = child as? TileSprite {
                    if sprite.containsPoint(point) {
                        gameState?.originalPoint = sprite.position
                        gameState?.draggedSprite = sprite
                        sprite.position = point
                        break
                    }
                } else if let squareSprite = child as? SquareSprite {
                    if let tileSprite = squareSprite.tileSprite {
                        if squareSprite.containsPoint(point) {
                            if let pickedUpSprite = squareSprite.pickupTileSprite() {
                                gameState?.originalPoint = squareSprite.originalPoint
                                gameState?.draggedSprite = pickedUpSprite
                                self.addChild(pickedUpSprite)
                                break
                            }
                        }
                    }
                } else if let labelNode = child as? SKLabelNode {
                    if labelNode.containsPoint(point) {
                        gameState?.submit()
                    }
                }
            }
        }
    }
	
	override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
		if let point = (touches.first as? UITouch)?.locationInNode(self) {
			if let sprite = gameState?.draggedSprite {
                sprite.position = point
            }
        }
    }
	
	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
		if let point = (touches.first as? UITouch)?.locationInNode(self) {
			if let sprite = gameState?.draggedSprite {
                var found = false
                var fallback: SquareSprite?     // Closest square to drop tile if hovered square is filled
                var fallbackOverlap: CGFloat = 0
                for child in self.children {
                    if let squareSprite = child as? SquareSprite {
                        if squareSprite.intersectsNode(sprite) {
                            if squareSprite.isEmpty() {
                                if squareSprite.frame.contains(point) {
                                    if let originalPoint = gameState?.originalPoint {
                                        squareSprite.dropTileSprite(sprite, originalPoint: originalPoint)
                                        found = true
                                        break
                                    }
                                }
                                var intersection = CGRectIntersection(squareSprite.frame, sprite.frame)
                                var overlap = CGRectGetWidth(intersection) + CGRectGetHeight(intersection)
                                if overlap > fallbackOverlap {
                                    fallback = squareSprite
                                    fallbackOverlap = overlap
                                }
                            }
                        }
                    }
                }
                if !found {
                    if let originalPoint = gameState?.originalPoint {
                        if let squareSprite = fallback {
                            squareSprite.dropTileSprite(sprite, originalPoint: originalPoint)
                        } else {
                            sprite.position = originalPoint
                        }
                    }
                }
                gameState?.originalPoint = nil
                gameState?.draggedSprite = nil
            }
        }
    }
	
	override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
		if let point = (touches.first as? UITouch)?.locationInNode(self) {
			if let sprite = gameState?.draggedSprite {
                if let origPoint = gameState?.originalPoint {
                    sprite.position = origPoint
                } else {
                    sprite.position = point
                }
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
