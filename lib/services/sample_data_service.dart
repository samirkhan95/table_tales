import '../models/restaurant.dart';
import '../models/visit.dart';
import 'database_service.dart';

class SampleDataService {
  static Future<void> loadSampleData(DatabaseService db) async {
    // 1. Restaurant: Osteria Francescana
    final r1 = Restaurant(
      name: 'Osteria Bella Vista',
      location: '142 Harbor Street, San Francisco, CA',
      cuisine: 'Italian',
      priceRange: 3,
      isFavorite: true,
      description: 'Charming seaside trattoria with handmade pasta and exquisite wood-fired pizza.',
      tags: ['Date Night', 'Romantic', 'Pasta', 'Wine'],
      website: 'https://osteriabellavista.example.com',
      phone: '(415) 555-0192',
    );
    await db.insertRestaurant(r1);

    await db.insertVisit(Visit(
      restaurantId: r1.id,
      visitDate: DateTime.now().subtract(const Duration(days: 4)),
      mealType: 'Dinner',
      occasion: 'Anniversary',
      notes: 'Celebrated our 3rd anniversary! The truffled tagliatelle was incredible, and the candlelit table by the window made it unforgettable.',
      rating: 5.0,
      amountSpent: 145.0,
      currency: '\$',
      tags: ['Anniversary', 'Must Revisit'],
    ));

    await db.insertVisit(Visit(
      restaurantId: r1.id,
      visitDate: DateTime.now().subtract(const Duration(days: 90)),
      mealType: 'Dinner',
      occasion: 'Spontaneous Date',
      notes: 'First time visiting on a rainy Tuesday. Tried the Chianti pair and Tiramisu.',
      rating: 4.8,
      amountSpent: 110.0,
      currency: '\$',
      tags: ['Wine'],
    ));

    // 2. Restaurant: Sakura Ramen Studio
    final r2 = Restaurant(
      name: 'Sakura Ramen Studio',
      location: '88 Bloom Avenue, Downtown',
      cuisine: 'Japanese',
      priceRange: 2,
      isFavorite: true,
      description: 'Cozy basement ramen bar with rich 18-hour tonkotsu broth and house-made noodles.',
      tags: ['Comfort Food', 'Casual', 'Ramen'],
      website: 'https://sakuraramen.example.com',
    );
    await db.insertRestaurant(r2);

    await db.insertVisit(Visit(
      restaurantId: r2.id,
      visitDate: DateTime.now().subtract(const Duration(days: 12)),
      mealType: 'Dinner',
      occasion: 'Casual Date',
      notes: 'Black garlic tonkotsu ramen with extra soft-boiled egg. Perfect cold evening meal!',
      rating: 4.9,
      amountSpent: 42.0,
      currency: '\$',
      tags: ['Ramen'],
    ));

    await db.insertVisit(Visit(
      restaurantId: r2.id,
      visitDate: DateTime.now().subtract(const Duration(days: 45)),
      mealType: 'Lunch',
      occasion: 'Weekend Date',
      notes: 'Quick lunch after exploring the local art museum.',
      rating: 4.5,
      amountSpent: 38.0,
      currency: '\$',
      tags: ['Lunch'],
    ));

    // 3. Restaurant: Le Petit Bistro
    final r3 = Restaurant(
      name: 'Le Petit Bistro',
      location: '204 Rue de Fleur, French Quarter',
      cuisine: 'French',
      priceRange: 4,
      isFavorite: false,
      description: 'Elegant Parisian style bistro with vintage jazz music and exceptional wine pairings.',
      tags: ['Fine Dining', 'Special Celebration', 'Wine'],
    );
    await db.insertRestaurant(r3);

    await db.insertVisit(Visit(
      restaurantId: r3.id,
      visitDate: DateTime.now().subtract(const Duration(days: 60)),
      mealType: 'Dinner',
      occasion: 'Birthday',
      notes: 'Birthday dinner celebration! Duck confit and French onion soup were highlights.',
      rating: 4.7,
      amountSpent: 210.0,
      currency: '\$',
      tags: ['Birthday'],
    ));

    // 4. Restaurant: El Sol Taqueria
    final r4 = Restaurant(
      name: 'El Sol Taqueria',
      location: '12 Mission District Way',
      cuisine: 'Mexican',
      priceRange: 1,
      isFavorite: true,
      description: 'Vibrant local taqueria serving authentic street tacos, fresh churros, and horchata.',
      tags: ['Street Food', 'Quick Bite', 'Tacos', 'Casual'],
    );
    await db.insertRestaurant(r4);

    await db.insertVisit(Visit(
      restaurantId: r4.id,
      visitDate: DateTime.now().subtract(const Duration(days: 20)),
      mealType: 'Lunch',
      occasion: 'Spontaneous Date',
      notes: 'Al pastor tacos with grilled pineapple and salsa verde. Incredible value!',
      rating: 4.9,
      amountSpent: 24.0,
      currency: '\$',
      tags: ['Tacos'],
    ));

    await db.insertVisit(Visit(
      restaurantId: r4.id,
      visitDate: DateTime.now().subtract(const Duration(days: 120)),
      mealType: 'Late Night',
      occasion: 'Post Event',
      notes: 'Late night churros and horchata after concert in the park.',
      rating: 4.8,
      amountSpent: 18.0,
      currency: '\$',
      tags: ['Dessert'],
    ));

    // 5. Restaurant: High Street Bakery & Cafe
    final r5 = Restaurant(
      name: 'High Street Bakery & Cafe',
      location: '55 High Street',
      cuisine: 'Café & Bakery',
      priceRange: 2,
      isFavorite: false,
      description: 'Artisanal sourdough, cardamom buns, and single-origin pour-overs.',
      tags: ['Breakfast', 'Coffee', 'Bakery', 'Weekend Morning'],
    );
    await db.insertRestaurant(r5);

    await db.insertVisit(Visit(
      restaurantId: r5.id,
      visitDate: DateTime.now().subtract(const Duration(days: 2)),
      mealType: 'Breakfast',
      occasion: 'Weekend Routine',
      notes: 'Sunday morning coffee & cardamom bun date. Our favorite calm ritual.',
      rating: 4.8,
      amountSpent: 22.0,
      currency: '\$',
      tags: ['Coffee'],
    ));
  }
}
