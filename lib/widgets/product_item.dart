import 'dart:ui';

import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../providers/cart.dart';
import '../providers/product.dart';

import '../screens/product_detail_screen.dart';

class ProductItem extends StatelessWidget {
//  final String id;
//  final String title;
//  final String imageUrl;
//
//  ProductItem({
//    this.id,
//    this.title,
//    this.imageUrl,
//  });

  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Product>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);
    final authData = Provider.of<Auth>(context, listen: false);
    return GridTile(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .pushNamed(ProductDetailScreen.routeName, arguments: product.id);
        },
        child: Stack(
          children: <Widget>[
            Card(
              elevation: 7,
              child: Container(
                foregroundDecoration: RotatedCornerDecoration(
                  color: Colors.green.shade700.withOpacity(0.9),
                  geometry: const BadgeGeometry(width: 56, height: 56),
                  textSpan: TextSpan(
                    text: '\$${product.price}',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(color: Colors.yellowAccent, blurRadius: 4)
                      ],
                    ),
                  ),
                ),
                child: Hero(
                  tag: product.id,
                  child: FadeInImage(
                    placeholder:
                        AssetImage('assets/images/product-placeholder.gif'),
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      footer: GridTileBar(
        title: Text(
          product.title,
          maxLines: 2,
          textScaleFactor: 0.9,
        ),
        leading: Consumer<Product>(
          builder: (ctx, product, _) => IconButton(
              icon: Icon(
                  product.isFavorite ? Icons.favorite : Icons.favorite_border),
              color: Theme.of(context).accentColor,
              onPressed: () {
                product.toggleFavoriteStatus(authData.token, authData.userId);
              }),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        trailing: IconButton(
            icon: Icon(Icons.shopping_cart),
            color: Theme.of(context).accentColor,
            onPressed: () {
              cart.addItem(product.id, product.price, product.title);
              Scaffold.of(context).hideCurrentSnackBar();
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.grey.shade800.withOpacity(0.9),
                  content: Text('Added item to cart!'),
                  duration: Duration(seconds: 1),
                  action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        cart.removeSingleItem(product.id);
                      }),
                ),
              );
            }),
      ),
    );
  }
}
