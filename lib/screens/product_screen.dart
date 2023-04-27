import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:productes_app/providers/product_form_provider.dart';
import 'package:productes_app/services/products_service.dart';
import 'package:productes_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../ui/input_decorations.dart';

/*
 Classe que defineix el format de la pantalla de producte. Aquesta es 
 divideix amb l'imatge i el formulari (que es defineix a una altre classe)
 */
class ProductScreen extends StatelessWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Inicialitzam el provider de Productes
    final productService = Provider.of<ProductsService>(context);
    return ChangeNotifierProvider(
      create: (_) => ProductFormProvider(productService.selectedProduct),
      child: _ProductScreenBody(productService: productService),
    );
  }
}

class _ProductScreenBody extends StatelessWidget {
  const _ProductScreenBody({
    Key? key,
    required this.productService,
  }) : super(key: key);

  final ProductsService productService;

  @override
  Widget build(BuildContext context) {
    //Inicialitzam el provider de la forma del producte
    final productForm = Provider.of<ProductFormProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //Imatge del producte
            Stack(
              children: [
                //Image
                ProductImage(url: productService.selectedProduct.picture),
                //Botó de retorn
                Positioned(
                  top: 60,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                //Botó de editar imatge
                Positioned(
                  top: 60,
                  right: 20,
                  child: IconButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      XFile? image;
                      //Cream un Dialog per triar com afegir l'imatge
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Tria una imatge",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: Colors.blue,
                                  thickness: 1,
                                ),
                                //Opció fer una fotografia
                                TextButton(
                                  onPressed: () async {
                                    image = await _picker.pickImage(
                                        source: ImageSource.camera);
                                    if (image != null) Navigator.pop(context);
                                  },
                                  child: const Text('Fes una foto'),
                                ),
                                //Opció de triar una imatge de la galeria
                                TextButton(
                                  onPressed: () async {
                                    image = await _picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image != null) Navigator.pop(context);
                                  },
                                  child: const Text(
                                      'Tria una imatge de la galeria'),
                                ),
                                //Sortir
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.comfortable,
                                    overlayColor: MaterialStateProperty.all(
                                        Colors.red[100]),
                                  ),
                                  child: const Text(
                                    'Tancar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                      //Si hem triat una imatge s'actualitza la copia del producte
                      if (image != null)
                        productService.updateSelectedImage(image!.path);
                    },
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            //Formulari
            _ProductForm(),
            SizedBox(
              height: 100,
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
          child: productService.isSaving
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(Icons.save_outlined),
          onPressed: productService.isSaving
              ? null
              : () async {
                  //Si és vàlid guardam els canvis del producte
                  if (!productForm.isValidForm()) return;
                  final String? imageUrl = await productService.uploadImage();
                  if (imageUrl != null)
                    productForm.tempProduct.picture = imageUrl;
                  productService.saveOrCreateProduct(productForm.tempProduct);
                }),
    );
  }
}

//Formulari del producte
class _ProductForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //Inicialitzam el provider de la forma del producte
    final productForm = Provider.of<ProductFormProvider>(context);
    /*Cream un producte temporal per anar guardant les modificacions abans de
    guardar*/
    final tempProduct = productForm.tempProduct;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        decoration: _buildBoxDecoration(),
        child: Form(
          key: productForm.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              SizedBox(height: 10),
              TextFormField(
                initialValue: tempProduct.name,
                onChanged: (value) => tempProduct.name = value,
                validator: (value) {
                  if (value == null || value.length < 1)
                    return "El nom és obligatori";
                },
                decoration: InputDecorations.authInputDecoration(
                    hintText: 'Nom del producte', labelText: 'Nom:'),
              ),
              SizedBox(height: 30),
              TextFormField(
                initialValue: "${tempProduct.price}",
                inputFormatters: [
                  /*Amb l'expressió regular feim que només es puguin afegir
                  dos decimals*/
                  FilteringTextInputFormatter.allow(
                      RegExp(r"^(\d+)?\.?\d{0,2}"))
                ],
                onChanged: (value) {
                  if (double.tryParse(value) == null) {
                    tempProduct.price = 0;
                  } else {
                    tempProduct.price = double.parse(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.length < 1)
                    return "El preu és obligatori";
                },
                keyboardType: TextInputType.number,
                decoration: InputDecorations.authInputDecoration(
                    hintText: 'Preu del producte', labelText: 'Preu:'),
              ),
              SizedBox(height: 30),
              SwitchListTile.adaptive(
                value: tempProduct.available,
                title: Text('Disponible'),
                activeColor: Colors.indigo,
                onChanged: productForm.updateAvailability,
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, 5),
              blurRadius: 5),
        ],
      );
}
