import StoreKit

@available(iOS 11.2, *)
public extension SKProduct {
  /// Detect if the product has a free trial period
  /// See `SKProductDiscount` class documentation
  var hasFreeTrial: Bool {
    self.introductoryPrice?.price == 0
  }

  /// Calculate **approximate** subscription price per year. You can use it to determine if there are any "save X %" options
  ///
  /// Based on `subscriptionPeriod.unit`.
  /// Nil if it's not a subscription.
  /// Weekly subscriptions are calculated with 52.1429 multiplier.
  /// Annual subscriptions are calculated with 365 multiplier.
  var oneYearApproximateSubscriptionPrice: Double? {
    guard let subscriptionPeriod = self.subscriptionPeriod else {
      return nil
    }
    let multiplier: Double
    switch subscriptionPeriod.unit {
    case .day:
      multiplier = 365
    case .week:
      multiplier = 52.1429
    case .month:
      multiplier = 12
    case .year:
      multiplier = 1
    @unknown default:
      return nil
    }
    return multiplier * self.price.doubleValue
  }
}

@available(iOS 11.2, *)
extension SKProduct.PeriodUnit: Comparable {
  public static func < (lhs: SKProduct.PeriodUnit, rhs: SKProduct.PeriodUnit) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}

@available(iOS 11.2, *)
public extension Collection where Iterator.Element == SKProduct {

  var hasMonthlySubscriptions: Bool {
    return self.contains(where: { $0.subscriptionPeriod?.unit == .month })
  }

  var hasAnnualSubscriptions: Bool {
    return self.contains(where: { $0.subscriptionPeriod?.unit == .year })
  }

  /// Take annual subscription, take monthly subscription and find difference in cost per year
  /// - Returns: 0 if annualSubscriptions.count > 1 or monthlySubscriptions.count > 1
  func calculatedPotentialDiscount() -> Double {
    let annualSubscriptions = self.filter { $0.subscriptionPeriod?.unit == .year }
    let monthlySubscriptions = self.filter { $0.subscriptionPeriod?.unit == .month && $0.subscriptionPeriod?.numberOfUnits == 1 }

    if annualSubscriptions.count > 1 || monthlySubscriptions.count > 1 {
      return 0
    }
    guard let annualSubscriptionPrice = annualSubscriptions.first?.oneYearApproximateSubscriptionPrice,
      let monthlySubscriptionPrice = monthlySubscriptions.first?.oneYearApproximateSubscriptionPrice else {
      return 0
    }
    return 1 - annualSubscriptionPrice / monthlySubscriptionPrice
  }
}
