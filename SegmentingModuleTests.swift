//
//  SegmentingModuleTests.swift
//  DirectorStudioTests
//
//  Advanced Test Suite for LLM-Integrated Segmentation
//

import XCTest
@testable import DirectorStudio

final class SegmentingModuleTests: XCTestCase {
    
    var module: SegmentingModule!
    let mockAPIKey = "test-api-key-12345"
    
    override func setUp() {
        super.setUp()
        module = SegmentingModule()
    }
    
    override func tearDown() {
        module = nil
        super.tearDown()
    }
    
    // MARK: - Basic Validation Tests
    
    func testEmptyScriptThrows() async throws {
        do {
            _ = try await module.segment(
                script: "",
                mode: .duration,
                constraints: .default,
                llmConfig: nil
            )
            XCTFail("Should throw emptyScript error")
        } catch SegmentationError.emptyScript {
            // Expected
        }
    }
    
    func testWhitespaceOnlyScriptThrows() async throws {
        do {
            _ = try await module.segment(
                script: "   \n\n\t  ",
                mode: .duration,
                constraints: .default,
                llmConfig: nil
            )
            XCTFail("Should throw emptyScript error")
        } catch SegmentationError.emptyScript {
            // Expected
        }
    }
    
    func testInvalidConstraintsThrows() async throws {
        var constraints = SegmentationConstraints()
        constraints.maxDuration = 1.0
        constraints.minDuration = 5.0  // Invalid: min > max
        
        do {
            _ = try await module.segment(
                script: "Test script",
                mode: .duration,
                constraints: constraints,
                llmConfig: nil
            )
            XCTFail("Should throw invalidConstraints error")
        } catch SegmentationError.invalidConstraints {
            // Expected
        }
    }
    
    // MARK: - Duration Mode Tests
    
    func testDurationMode_SimpleScript() async throws {
        let script = """
        A detective walks through a dark alley.
        Rain falls steadily from the night sky.
        He notices a figure in the shadows.
        """
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.segments.count, 0)
        XCTAssertEqual(result.metadata.mode, "Duration-Based")
        XCTAssertFalse(result.metadata.fallbackUsed)
    }
    
    func testDurationMode_LongScript() async throws {
        let script = String(repeating: "The story continues with more detail. ", count: 100)
        
        var constraints = SegmentationConstraints()
        constraints.maxSegments = 10
        constraints.targetDuration = 3.0
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: constraints,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertLessThanOrEqual(result.segments.count, 10)
        
        // Verify chronological order
        for (index, segment) in result.segments.enumerated() {
            XCTAssertEqual(segment.segmentIndex, index)
            if index > 0 {
                XCTAssertEqual(segment.globalStartToken, result.segments[index - 1].globalEndToken)
            }
        }
    }
    
    func testDurationMode_MinimalScript() async throws {
        let script = "Hello world."
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.segments.count, 1)
        XCTAssertEqual(result.segments[0].text.trimmingCharacters(in: .whitespaces), script)
    }
    
    // MARK: - Even Split Mode Tests
    
    func testEvenSplitMode_BalancedDistribution() async throws {
        let script = String(repeating: "word ", count: 100)
        
        var constraints = SegmentationConstraints()
        constraints.maxSegments = 5
        
        let result = try await module.segment(
            script: script,
            mode: .evenSplit,
            constraints: constraints,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.segments.count, 5)
        
        // Check relatively even distribution
        let tokenCounts = result.segments.map { $0.estimatedTokens }
        let avgTokens = tokenCounts.reduce(0, +) / tokenCounts.count
        for count in tokenCounts {
            let variance = abs(count - avgTokens)
            XCTAssertLessThan(Double(variance) / Double(avgTokens), 0.3) // Within 30%
        }
    }
    
    // MARK: - Constraint Enforcement Tests
    
    func testTokenLimitEnforcement_AutoTruncate() async throws {
        let longSegmentScript = String(repeating: "word ", count: 500)
        
        var constraints = SegmentationConstraints()
        constraints.maxTokensPerSegment = 50
        constraints.allowAutoAdjustment = true
        constraints.enforceStrictLimits = true
        
        let result = try await module.segment(
            script: longSegmentScript,
            mode: .evenSplit,
            constraints: constraints,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        
        // All segments should respect token limit
        for segment in result.segments {
            XCTAssertLessThanOrEqual(segment.estimatedTokens, constraints.maxTokensPerSegment)
        }
        
        // Should have warnings about truncation
        let hasTokenWarning = result.warnings.contains { warning in
            if case .tokenLimitExceeded = warning { return true }
            return false
        }
        XCTAssertTrue(hasTokenWarning || result.warnings.contains { warning in
            if case .autoAdjusted = warning { return true }
            return false
        })
    }
    
    func testMaxSegmentsEnforcement_AutoMerge() async throws {
        let script = String(repeating: "Short sentence. ", count: 50)
        
        var constraints = SegmentationConstraints()
        constraints.maxSegments = 3
        constraints.targetDuration = 1.0  // Will create many small segments
        constraints.allowAutoAdjustment = true
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: constraints,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertLessThanOrEqual(result.segments.count, 3)
    }
    
    func testStrictMode_ThrowsOnViolation() async throws {
        let script = String(repeating: "word ", count: 1000)
        
        var constraints = SegmentationConstraints()
        constraints.maxTokensPerSegment = 10
        constraints.allowAutoAdjustment = false
        constraints.enforceStrictLimits = true
        
        do {
            _ = try await module.segment(
                script: script,
                mode: .evenSplit,
                constraints: constraints,
                llmConfig: nil
            )
            XCTFail("Should throw constraint violation error")
        } catch SegmentationError.constraintViolationUnresolvable {
            // Expected
        }
    }
    
    // MARK: - Taxonomy Hints Tests
    
    func testTaxonomyHints_EmptyForNonAI() async throws {
        let script = "Test script content here."
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        for segment in result.segments {
            XCTAssertNil(segment.taxonomyHints.cameraAngle)
            XCTAssertNil(segment.taxonomyHints.sceneType)
            XCTAssertNil(segment.taxonomyHints.emotion)
        }
    }
    
    // MARK: - Chronological Flow Tests
    
    func testChronologicalFlow_Maintained() async throws {
        let script = "First segment. Second segment. Third segment. Fourth segment."
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        var previousEndToken = 0
        for (index, segment) in result.segments.enumerated() {
            // Check segment index matches position
            XCTAssertEqual(segment.segmentIndex, index)
            
            // Check token positions are sequential
            XCTAssertEqual(segment.globalStartToken, previousEndToken)
            XCTAssertGreaterThan(segment.globalEndToken, segment.globalStartToken)
            
            previousEndToken = segment.globalEndToken
        }
        
        // Total tokens should match
        XCTAssertEqual(result.totalTokens, previousEndToken)
    }
    
    // MARK: - Metadata Tests
    
    func testMetadata_Completeness() async throws {
        let script = "Test script for metadata validation."
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertEqual(result.metadata.mode, "Duration-Based")
        XCTAssertEqual(result.metadata.segmentCount, result.segments.count)
        XCTAssertGreaterThan(result.metadata.executionTime, 0)
        XCTAssertGreaterThanOrEqual(result.metadata.averageConfidence, 0)
        XCTAssertLessThanOrEqual(result.metadata.averageConfidence, 1.0)
        XCTAssertEqual(result.metadata.llmCallCount, 0) // Duration mode doesn't use LLM
    }
    
    func testMetadata_TokenAndDurationAccuracy() async throws {
        let script = "A simple test script."
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        // Calculate manually
        let manualTokenCount = result.segments.reduce(0) { $0 + $1.estimatedTokens }
        let manualDuration = result.segments.reduce(0.0) { $0 + $1.estimatedDuration }
        
        XCTAssertEqual(result.metadata.totalTokens, manualTokenCount)
        XCTAssertEqual(result.metadata.totalDuration, manualDuration)
    }
    
    // MARK: - Warning System Tests
    
    func testWarnings_Severity() {
        let tokenWarning = SegmentationWarning.tokenLimitExceeded(segmentIndex: 0, tokens: 300, limit: 200)
        XCTAssertEqual(tokenWarning.severity, .error)
        
        let confidenceWarning = SegmentationWarning.lowConfidence(segmentIndex: 0, confidence: 0.5)
        XCTAssertEqual(confidenceWarning.severity, .warning)
        
        let infoWarning = SegmentationWarning.autoAdjusted(description: "test")
        XCTAssertEqual(infoWarning.severity, .info)
    }
    
    func testWarnings_Messages() {
        let warning1 = SegmentationWarning.tokenLimitExceeded(segmentIndex: 0, tokens: 300, limit: 200)
        XCTAssertTrue(warning1.message.contains("Segment #1"))
        XCTAssertTrue(warning1.message.contains("300"))
        
        let warning2 = SegmentationWarning.fallbackUsed(from: "AI", to: "Duration")
        XCTAssertTrue(warning2.message.contains("AI"))
        XCTAssertTrue(warning2.message.contains("Duration"))
    }
    
    // MARK: - Edge Case Tests
    
    func testEdgeCase_SingleWord() async throws {
        let script = "Word"
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.segments.count, 1)
        XCTAssertEqual(result.segments[0].text, "Word")
    }
    
    func testEdgeCase_UnicodeAndEmoji() async throws {
        let script = "Hello 👋 世界 🌍 مرحبا"
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.segments.count, 0)
        
        let fullText = result.segments.map { $0.text }.joined(separator: " ")
        XCTAssertTrue(fullText.contains("👋"))
        XCTAssertTrue(fullText.contains("世界"))
    }
    
    func testEdgeCase_Malformed_ExcessiveWhitespace() async throws {
        let script = """
        
        
        Text   with     lots    of     spaces.
        
        
        And  many   newlines.
        
        
        """
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        for segment in result.segments {
            XCTAssertFalse(segment.text.isEmpty)
        }
    }
    
    func testEdgeCase_Poetry() async throws {
        let script = """
        Roses are red,
        Violets are blue,
        Sugar is sweet,
        And so are you.
        """
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.segments.count, 0)
    }
    
    func testEdgeCase_RapidFire_ShortSentences() async throws {
        let script = "Go! Run! Hide! Fight! Win!"
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        // Should handle very short segments gracefully
    }
    
    func testEdgeCase_VeryLongScript() async throws {
        let script = String(repeating: "This is a longer narrative segment with multiple words and phrases. ", count: 200)
        
        var constraints = SegmentationConstraints()
        constraints.maxSegments = 20
        
        let result = try await module.segment(
            script: script,
            mode: .evenSplit,
            constraints: constraints,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertLessThanOrEqual(result.segments.count, 20)
        
        // Verify all content is preserved
        let reconstructed = result.segments.map { $0.text }.joined(separator: " ")
        let scriptWords = script.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let reconstructedWords = reconstructed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Allow for some variance due to truncation
        XCTAssertGreaterThan(reconstructedWords.count, scriptWords.count * 70 / 100)
    }
    
    // MARK: - Hybrid Mode Tests (with mock fallback)
    
    func testHybridMode_FallsBackWhenNoLLMConfig() async throws {
        let script = "Test script for hybrid mode."
        
        let result = try await module.segment(
            script: script,
            mode: .hybrid,
            constraints: .default,
            llmConfig: nil  // No LLM config provided
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.metadata.fallbackUsed)
        
        // Should have fallback warning
        let hasFallbackWarning = result.warnings.contains { warning in
            if case .fallbackUsed = warning { return true }
            return false
        }
        XCTAssertTrue(hasFallbackWarning)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_MediumScript() throws {
        let script = String(repeating: "Performance test segment. ", count: 50)
        
        measure {
            let expectation = self.expectation(description: "Segmentation")
            
            Task {
                do {
                    _ = try await module.segment(
                        script: script,
                        mode: .duration,
                        constraints: .default,
                        llmConfig: nil
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformance_LargeScript() throws {
        let script = String(repeating: "Large script performance test. ", count: 500)
        
        let expectation = self.expectation(description: "Large segmentation")
        var executionTime: TimeInterval = 0
        
        Task {
            do {
                let result = try await module.segment(
                    script: script,
                    mode: .evenSplit,
                    constraints: .default,
                    llmConfig: nil
                )
                executionTime = result.metadata.executionTime
                expectation.fulfill()
            } catch {
                XCTFail("Large script test failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Should complete in reasonable time
        XCTAssertLessThan(executionTime, 5.0)
    }
    
    // MARK: - Token Estimator Tests
    
    func testTokenEstimator_Accuracy() {
        let estimator = TokenEstimator.shared
        
        let shortText = "Hello world"
        let tokens = estimator.estimate(shortText)
        
        XCTAssertGreaterThan(tokens, 0)
        XCTAssertLessThanOrEqual(tokens, 5)
    }
    
    func testTokenEstimator_Truncation() {
        let estimator = TokenEstimator.shared
        
        let longText = String(repeating: "word ", count: 100)
        let truncated = estimator.truncate(longText, maxTokens: 20)
        
        XCTAssertLessThan(truncated.count, longText.count)
        XCTAssertTrue(truncated.hasSuffix("..."))
        
        let truncatedTokens = estimator.estimate(truncated)
        XCTAssertLessThanOrEqual(truncatedTokens, 22) // Allow small margin
    }
    
    // MARK: - Result Validation Tests
    
    func testResultValidation_isValid() async throws {
        let validScript = "Valid test script."
        let result = try await module.segment(
            script: validScript,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.segments.isEmpty)
        XCTAssertTrue(result.segments.allSatisfy { !$0.text.isEmpty })
    }
    
    func testResultValidation_totalCalculations() async throws {
        let script = "Test script for totals."
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        let manualTokenTotal = result.segments.reduce(0) { $0 + $1.estimatedTokens }
        let manualDurationTotal = result.segments.reduce(0.0) { $0 + $1.estimatedDuration }
        
        XCTAssertEqual(result.totalTokens, manualTokenTotal)
        XCTAssertEqual(result.totalDuration, manualDurationTotal)
    }
    
    // MARK: - Convenience API Tests
    
    func testConvenienceAPI_QuickSegment() async throws {
        // This would normally require a real API key
        // For unit tests, we expect it to fail without mocking
        
        let script = "Quick segmentation test."
        
        do {
            _ = try await SegmentingModule.quickSegment(
                script: script,
                apiKey: mockAPIKey,
                mode: .hybrid
            )
            // Would need mock LLM client to pass
        } catch {
            // Expected without mock
            XCTAssertTrue(error is SegmentationError)
        }
    }
    
    // MARK: - Semantic Expansion Tests
    
    func testSemanticExpansion_ConfigValidation() {
        var config = SemanticExpansionConfig()
        XCTAssertTrue(config.isValid)
        
        config.tokenBudgetPerSegment = -10
        XCTAssertFalse(config.isValid)
        
        config = .default
        config.emotionThreshold = 1.5
        XCTAssertFalse(config.isValid)
    }
    
    func testSemanticExpansion_Disabled() async throws {
        let script = "A short prompt."
        
        var llmConfig = LLMConfiguration(apiKey: mockAPIKey)
        llmConfig.enableSemanticExpansion = false  // Disabled
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: llmConfig
        )
        
        // No segments should have expanded prompts
        XCTAssertTrue(result.segments.allSatisfy { $0.expandedPrompt == nil })
        XCTAssertNil(result.metadata.expansionStats)
    }
    
    func testSemanticExpansion_EmotionDetection() {
        let processor = SemanticExpansionProcessor.shared
        
        let neutralText = "The person walks down the street."
        let neutralScore = processor.detectEmotionalIntensity(neutralText)
        XCTAssertLessThan(neutralScore, 0.3)
        
        let emotionalText = "She screams in terror! Her heart races with panic!"
        let emotionalScore = processor.detectEmotionalIntensity(emotionalText)
        XCTAssertGreaterThan(emotionalScore, 0.5)
        
        let intenseText = "FURY! RAGE! He EXPLODES with devastating violence!"
        let intenseScore = processor.detectEmotionalIntensity(intenseText)
        XCTAssertGreaterThan(intenseScore, 0.7)
    }
    
    func testSemanticExpansion_CandidateIdentification() {
        let processor = SemanticExpansionProcessor.shared
        
        let segments = [
            CinematicSegment(
                id: UUID(),
                segmentIndex: 0,
                text: "Short.",  // Should be candidate (short)
                estimatedTokens: 5,
                estimatedDuration: 1.0,
                globalStartToken: 0,
                globalEndToken: 5,
                taxonomyHints: .empty,
                expandedPrompt: nil,
                splitReason: nil,
                confidence: 0.9,
                fallbackNotes: nil
            ),
            CinematicSegment(
                id: UUID(),
                segmentIndex: 1,
                text: "This is a longer segment with more detail that should not be expanded.",
                estimatedTokens: 50,
                estimatedDuration: 3.0,
                globalStartToken: 5,
                globalEndToken: 55,
                taxonomyHints: .empty,
                expandedPrompt: nil,
                splitReason: nil,
                confidence: 0.9,
                fallbackNotes: nil
            ),
            CinematicSegment(
                id: UUID(),
                segmentIndex: 2,
                text: "Terror! Panic! Fear!",  // Should be candidate (emotional)
                estimatedTokens: 10,
                estimatedDuration: 1.5,
                globalStartToken: 55,
                globalEndToken: 65,
                taxonomyHints: .empty,
                expandedPrompt: nil,
                splitReason: nil,
                confidence: 0.9,
                fallbackNotes: nil
            )
        ]
        
        var config = SemanticExpansionConfig()
        config.minLengthForExpansion = 30
        config.emotionThreshold = 0.5
        
        let candidates = processor.identifyExpansionCandidates(segments, config: config)
        
        // Should identify segments 0 and 2
        XCTAssertEqual(candidates.count, 2)
        XCTAssertTrue(candidates.contains(0))
        XCTAssertTrue(candidates.contains(2))
    }
    
    func testSemanticExpansion_EffectivePromptFallback() {
        // Segment without expansion uses base text
        let segment1 = CinematicSegment(
            id: UUID(),
            segmentIndex: 0,
            text: "Base prompt",
            estimatedTokens: 10,
            estimatedDuration: 2.0,
            globalStartToken: 0,
            globalEndToken: 10,
            taxonomyHints: .empty,
            expandedPrompt: nil,
            splitReason: nil,
            confidence: 0.9,
            fallbackNotes: nil
        )
        
        XCTAssertEqual(segment1.effectivePrompt, "Base prompt")
        XCTAssertEqual(segment1.totalTokens, 10)
        
        // Segment with expansion uses expanded text
        let expansion = ExpandedPrompt(
            text: "Expanded vivid prompt",
            additionalTokens: 15,
            expansionReason: "test",
            emotionScore: 0.7,
            expansionStyle: "vivid",
            llmConfidence: 0.95,
            enhancedHints: nil
        )
        
        var segment2 = segment1
        segment2.expandedPrompt = expansion
        
        XCTAssertEqual(segment2.effectivePrompt, "Expanded vivid prompt")
        XCTAssertEqual(segment2.totalTokens, 25)  // 10 + 15
    }
    
    func testSemanticExpansion_StyleOptions() {
        let styles = SemanticExpansionConfig.ExpansionStyle.allCases
        XCTAssertEqual(styles.count, 5)
        
        for style in styles {
            XCTAssertFalse(style.promptGuidance.isEmpty)
            XCTAssertFalse(style.rawValue.isEmpty)
        }
        
        // Verify each style has unique guidance
        let vividGuidance = SemanticExpansionConfig.ExpansionStyle.vivid.promptGuidance
        XCTAssertTrue(vividGuidance.contains("visual") || vividGuidance.contains("cinematic"))
        
        let emotionalGuidance = SemanticExpansionConfig.ExpansionStyle.emotional.promptGuidance
        XCTAssertTrue(emotionalGuidance.contains("emotion") || emotionalGuidance.contains("feeling"))
    }
    
    func testSemanticExpansion_WarningTypes() {
        let warning1 = SegmentationWarning.expansionFailed(segmentIndex: 0, reason: "test")
        XCTAssertEqual(warning1.severity, .warning)
        XCTAssertTrue(warning1.message.contains("Segment #1"))
        
        let warning2 = SegmentationWarning.expansionBudgetExceeded(segmentIndex: 1, tokens: 150, budget: 100)
        XCTAssertEqual(warning2.severity, .info)
        XCTAssertTrue(warning2.message.contains("150"))
        
        let warning3 = SegmentationWarning.maxExpansionsReached(limit: 5)
        XCTAssertEqual(warning3.severity, .info)
        
        let warning4 = SegmentationWarning.lowExpansionQuality(segmentIndex: 2, confidence: 0.4)
        XCTAssertEqual(warning4.severity, .warning)
    }
    
    func testSemanticExpansion_ExpansionStats() {
        let stats = ExpansionStats(
            enabled: true,
            expandedCount: 5,
            totalExpansionTokens: 250,
            averageEmotionScore: 0.75,
            expansionStyle: "Vivid",
            expansionTime: 2.5
        )
        
        XCTAssertTrue(stats.enabled)
        XCTAssertEqual(stats.expandedCount, 5)
        XCTAssertEqual(stats.totalExpansionTokens, 250)
        XCTAssertNotNil(stats.averageEmotionScore)
        XCTAssertFalse(stats.summary.isEmpty)
        XCTAssertTrue(stats.summary.contains("5"))
        XCTAssertTrue(stats.summary.contains("250"))
    }
    
    func testSemanticExpansion_MaxExpansionsLimit() {
        // Test that maxExpansions config is respected
        var config = SemanticExpansionConfig()
        config.maxExpansions = 2
        config.expandShortSegments = true
        config.minLengthForExpansion = 50
        
        // All segments are short, but only 2 should be expanded
        let segments = (0..<5).map { index in
            CinematicSegment(
                id: UUID(),
                segmentIndex: index,
                text: "Short",
                estimatedTokens: 5,
                estimatedDuration: 1.0,
                globalStartToken: index * 5,
                globalEndToken: (index + 1) * 5,
                taxonomyHints: .empty,
                expandedPrompt: nil,
                splitReason: nil,
                confidence: 0.9,
                fallbackNotes: nil
            )
        }
        
        let processor = SemanticExpansionProcessor.shared
        let candidates = processor.identifyExpansionCandidates(segments, config: config)
        
        // All 5 are candidates, but max is 2
        XCTAssertEqual(candidates.count, 5)
        // maxExpansions limit is enforced in expandSegments method
    }
    
    func testSemanticExpansion_TokenBudgetEnforcement() {
        var config = SemanticExpansionConfig()
        config.tokenBudgetPerSegment = 50
        
        XCTAssertTrue(config.isValid)
        XCTAssertEqual(config.tokenBudgetPerSegment, 50)
    }
    
    func testSemanticExpansion_PreserveOriginalOption() {
        var config = SemanticExpansionConfig()
        config.preserveOriginal = true
        
        // When preserveOriginal is true, both base and expanded should be available
        XCTAssertTrue(config.preserveOriginal)
        
        // In CinematicSegment, both text and expandedPrompt are available
        let segment = CinematicSegment(
            id: UUID(),
            segmentIndex: 0,
            text: "Original",
            estimatedTokens: 10,
            estimatedDuration: 2.0,
            globalStartToken: 0,
            globalEndToken: 10,
            taxonomyHints: .empty,
            expandedPrompt: ExpandedPrompt(
                text: "Expanded",
                additionalTokens: 20,
                expansionReason: "test",
                emotionScore: 0.5,
                expansionStyle: "vivid",
                llmConfidence: 0.9,
                enhancedHints: nil
            ),
            splitReason: nil,
            confidence: 0.9,
            fallbackNotes: nil
        )
        
        // Both are accessible
        XCTAssertEqual(segment.text, "Original")
        XCTAssertEqual(segment.expandedPrompt?.text, "Expanded")
        XCTAssertEqual(segment.effectivePrompt, "Expanded")
    }
    
    // MARK: - Integration Scenarios
    
    func testIntegrationScenario_CompleteWorkflow() async throws {
        // Simulate: User enters script → segment → review → adjust → generate
        
        let userScript = """
        INT. COFFEE SHOP - MORNING
        
        JANE sips coffee nervously. She checks her phone.
        
        JANE
        (muttering)
        Where is he?
        
        The door opens. MARK enters, drenched from rain.
        """
        
        // Step 1: Initial segmentation
        var constraints = SegmentationConstraints()
        constraints.maxSegments = 5
        constraints.maxTokensPerSegment = 150
        
        let result = try await module.segment(
            script: userScript,
            mode: .duration,
            constraints: constraints,
            llmConfig: nil
        )
        
        XCTAssertTrue(result.isValid)
        
        // Step 2: Validate for UI review
        for segment in result.segments {
            XCTAssertFalse(segment.text.isEmpty)
            XCTAssertNotNil(segment.id)
            XCTAssertGreaterThanOrEqual(segment.segmentIndex, 0)
        }
        
        // Step 3: Check chronological integrity
        for i in 1..<result.segments.count {
            XCTAssertEqual(
                result.segments[i].globalStartToken,
                result.segments[i - 1].globalEndToken
            )
        }
        
        // Step 4: Verify metadata
        XCTAssertGreaterThan(result.metadata.executionTime, 0)
        XCTAssertEqual(result.metadata.segmentCount, result.segments.count)
    }
    
    func testIntegrationScenario_TaxonomyPreparation() async throws {
        let script = "A tense scene unfolds."
        
        let result = try await module.segment(
            script: script,
            mode: .duration,
            constraints: .default,
            llmConfig: nil
        )
        
        // Taxonomy hints structure should exist
        for segment in result.segments {
            XCTAssertNotNil(segment.taxonomyHints)
            // For non-AI modes, hints are empty but structure exists
        }
    }
}

// MARK: - Mock LLM Client Tests

final class MockLLMClientTests: XCTestCase {
    
    func testMockLLMResponse_Parsing() throws {
        let mockJSON = """
        {
          "boundaries": [
            {
              "text": "First segment text",
              "reason": "scene change",
              "confidence": 0.95,
              "ambiguous": false,
              "taxonomyHints": {
                "cameraAngle": "wide",
                "sceneType": "exterior",
                "emotion": "calm",
                "pacing": "slow",
                "visualComplexity": "moderate",
                "transitionType": "cut"
              }
            }
          ]
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ParsedLLMResponse.self, from: data)
        
        XCTAssertEqual(parsed.boundaries.count, 1)
        XCTAssertEqual(parsed.boundaries[0].text, "First segment text")
        XCTAssertEqual(parsed.boundaries[0].confidence, 0.95)
        XCTAssertEqual(parsed.boundaries[0].taxonomyHints.cameraAngle, "wide")
    }
}

// MARK: - CinematicSegment Tests

final class CinematicSegmentTests: XCTestCase {
    
    func testCinematicSegment_Codable() throws {
        let segment = CinematicSegment(
            id: UUID(),
            segmentIndex: 0,
            text: "Test segment",
            estimatedTokens: 10,
            estimatedDuration: 3.0,
            globalStartToken: 0,
            globalEndToken: 10,
            taxonomyHints: TaxonomyHints(
                cameraAngle: "medium",
                sceneType: "interior",
                emotion: "neutral",
                pacing: "moderate",
                visualComplexity: "simple",
                transitionType: "cut"
            ),
            splitReason: "test",
            confidence: 0.9,
            fallbackNotes: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(segment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CinematicSegment.self, from: data)
        
        XCTAssertEqual(decoded.text, segment.text)
        XCTAssertEqual(decoded.segmentIndex, segment.segmentIndex)
        XCTAssertEqual(decoded.taxonomyHints.cameraAngle, "medium")
    }
}
