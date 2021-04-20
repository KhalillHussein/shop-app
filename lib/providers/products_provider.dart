import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';

import './product.dart';

class ProductsProvider with ChangeNotifier {
  List<Product> _items = [
//    Product(
//      id: 'p1',
//      title: 'Planet Comics No. 55',
//      description:
//          'Since this comic book was first published in the U.S. before 1964, the original copyright lasted 27 years from the end of the year of first publication',
//      price: 29.99,
//      imageUrl:
//          'https://upload.wikimedia.org/wikipedia/commons/b/b5/Planet_Comics_55.jpg',
//    ),
//    Product(
//      id: 'p2',
//      title: 'Exciting Comics #53',
//      description:
//          'Works copyrighted before 1964 had to have the copyright renewed sometime in the 28th year. If the copyright was not renewed the work is in the public domain.',
//      price: 59.99,
//      imageUrl:
//          'https://upload.wikimedia.org/wikipedia/commons/3/37/ExcitingComics_53.jpg',
//    ),
//    Product(
//      id: 'p3',
//      title: 'Fox Feature Syndicate\'s Zoot #7',
//      description:
//          'Since this comic book was first published in the U.S. before 1964, the original copyright lasted 27 years from the end of the year of first publication. ',
//      price: 39.99,
//      imageUrl:
//          'https://upload.wikimedia.org/wikipedia/commons/d/d8/Zoot_Comics_No_7.jpg',
//    ),
//    Product(
//      id: 'p4',
//      title: 'Planet Comics #21',
//      description:
//          'Since this comic book was first published in the U.S. before 1964, the original copyright lasted 27 years from the end of the year of first publication.',
//      price: 49.99,
//      imageUrl:
//          'https://upload.wikimedia.org/wikipedia/commons/8/88/Planet_Comics_21.jpg',
//    ),
  ];

  final String authToken;
  final String userId;

  ProductsProvider(this.authToken,this.userId,this._items);

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  List<Product> get items {
    return [..._items];
  }

  Future<void> fetchAndGetProducts([bool filterByUser=false]) async {
    final filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"': '';
    var url = 'https://my-flutter-f53db.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);
      final List<Product> loadedProducts = [];
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url = 'https://my-flutter-f53db.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(
          Product(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            price: prodData['price'],
            isFavorite: favoriteData == null ? false :favoriteData[prodId] ?? false,
            imageUrl: prodData['imageUrl'],
          ),
        );
        _items = loadedProducts;
        notifyListeners();
      });
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url = 'https://my-flutter-f53db.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId,
        }),
      );
      print(json.decode(response.body));
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = 'https://my-flutter-f53db.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(
        url,
        body: json.encode({
          'title': newProduct.title,
          'description': newProduct.description,
          'price': newProduct.price,
          'imageUrl': newProduct.imageUrl,
        }),
      );
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = 'https://my-flutter-f53db.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
