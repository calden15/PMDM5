import 'package:flutter/material.dart';
import 'package:productes_app/models/models.dart';
import 'package:productes_app/screens/loading_screen.dart';
import 'package:productes_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../services/products_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Inicialitzam el provider necessari
    final productsService = Provider.of<ProductsService>(context);

    //Mentres els productes no s'hagin carregat mostram la pantalla de carrega
    if (productsService.isLoading) return LoadingScreen();
    return Scaffold(
      appBar: AppBar(
        title: Text('Productes'),
      ),
      body: ListView.builder(
        itemCount: productsService.products.length,
        itemBuilder: (BuildContext context, int index) => GestureDetector(
            //Mostram tots els productes a un listview
            child: ProductCard(product: productsService.products[index]),
            /*Feim una còpia del producte seleccionat i obrim la pantalla de
            producte*/
            onTap: () {
              productsService.selectedProduct =
                  productsService.products[index].copy();
              Navigator.of(context).pushNamed('product');
            }),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          //Reiniciam la imatge per evitar errors
          productsService.newPicture = null;
          //Cream un producte nou per editar
          productsService.selectedProduct = Product(
            available: true,
            name: "",
            price: 0,
          );
          Navigator.of(context).pushNamed('product');
        },
      ),
    );
  }
}
