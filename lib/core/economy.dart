/// Shop and the gentle hint / heart rules. Prices are what to enter in Play Console.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.hints,
    required this.removeAds,
    required this.consumable,
  });

  final String id;
  final String title;
  final String priceLabel;
  final int hints;
  final bool removeAds;
  final bool consumable;
}

abstract final class StoreCatalog {
  static const removeAds = 'remove_ads';
  static const hintsSmall = 'hints_small';
  static const hintsMedium = 'hints_medium';
  static const hintsLarge = 'hints_large';
  static const starterBundle = 'starter_bundle';

  static const products = <StoreProduct>[
    StoreProduct(
      id: removeAds,
      title: 'Remove ads',
      priceLabel: r'$4.99',
      hints: 0,
      removeAds: true,
      consumable: false,
    ),
    StoreProduct(
      id: hintsSmall,
      title: '5 hints',
      priceLabel: r'$0.99',
      hints: 5,
      removeAds: false,
      consumable: true,
    ),
    StoreProduct(
      id: hintsMedium,
      title: '15 hints',
      priceLabel: r'$2.49',
      hints: 15,
      removeAds: false,
      consumable: true,
    ),
    StoreProduct(
      id: hintsLarge,
      title: '40 hints',
      priceLabel: r'$4.99',
      hints: 40,
      removeAds: false,
      consumable: true,
    ),
    StoreProduct(
      id: starterBundle,
      title: 'Starter bundle',
      priceLabel: r'$2.99',
      hints: 10,
      removeAds: true,
      consumable: false,
    ),
  ];

  static const startingHints = 3;
  static const heartsPerPuzzle = 3;

  static StoreProduct? find(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}

class Wallet {
  const Wallet({required this.hints, required this.removeAds, required this.starterClaimed});

  final int hints;
  final bool removeAds;
  final bool starterClaimed;

  Wallet apply(String productId, {required bool restore}) {
    final product = StoreCatalog.find(productId);
    if (product == null) return this;
    if (product.consumable) {
      if (restore) return this;
      return Wallet(hints: hints + product.hints, removeAds: removeAds, starterClaimed: starterClaimed);
    }
    if (product.id == StoreCatalog.starterBundle) {
      if (starterClaimed) {
        return Wallet(hints: hints, removeAds: true, starterClaimed: true);
      }
      return Wallet(hints: hints + product.hints, removeAds: true, starterClaimed: true);
    }
    return Wallet(hints: hints, removeAds: true, starterClaimed: starterClaimed);
  }
}

enum HeartCheck { won, free, charged, needsHeart }

/// A wrong check is one that finds a broken placement. An unfinished board is not a mistake.
HeartCheck judgeCheck({required bool trackHearts, required int hearts, required bool won, required bool mistake}) {
  if (won) return HeartCheck.won;
  if (!mistake || !trackHearts) return HeartCheck.free;
  if (hearts <= 0) return HeartCheck.needsHeart;
  return HeartCheck.charged;
}

enum HintAccess { spendWallet, watchAd }

HintAccess hintAccess(int balance) => balance > 0 ? HintAccess.spendWallet : HintAccess.watchAd;

int refillHeartCount(int hearts) {
  if (hearts >= StoreCatalog.heartsPerPuzzle) return StoreCatalog.heartsPerPuzzle;
  return hearts + 1;
}

bool shouldShowForcedAd({required bool removeAds, required bool pacingAllows}) {
  return !removeAds && pacingAllows;
}
