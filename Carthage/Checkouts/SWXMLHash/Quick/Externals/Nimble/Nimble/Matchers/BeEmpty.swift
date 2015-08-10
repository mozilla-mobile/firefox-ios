import Foundation

public func beEmpty<S: SequenceType>() -> MatcherFunc<S?> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be empty"
        let actualSeq = actualExpression.evaluate()
        if actualSeq == nil {
            return true
        }
        var generator = actualSeq!.generate()
        return generator.next() == nil
    }
}

public func beEmpty() -> MatcherFunc<NSString?> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be empty"
        let actualString = actualExpression.evaluate()
        return actualString == nil || actualString!.length == 0
    }
}

public func beEmpty() -> MatcherFunc<NMBCollection?> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be empty"
        let actual = actualExpression.evaluate()
        return actual == nil || actual!.count == 0
    }
}

extension NMBObjCMatcher {
    class func beEmptyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ actualBlock() as? NMBCollection })
            let expr = Expression(expression: block, location: location)
            return beEmpty().matches(expr, failureMessage: failureMessage)
        }
    }
}
