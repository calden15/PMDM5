import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:productes_app/models/models.dart';
import 'package:http/http.dart' as http;

class ProductsService extends ChangeNotifier {
  //Url base de la meva api
  final String _baseUrl =
      "flutter-app-productes-75737-default-rtdb.europe-west1.firebasedatabase.app";
  //Llista de productes
  final List<Product> products = [];
  //Producte que modificam
  late Product selectedProduct;
  //Arxiu que contindrà una imatge
  File? newPicture;

  bool isLoading = true;
  bool isSaving = false;

  ProductsService() {
    this.loadProducts();
  }

  /*Mètode que crea un url de la nostra api, agafa tots els productes en format
  json i les introdueix a la llista de productes. */
  Future loadProducts() async {
    isLoading = true;
    notifyListeners();
    final url = Uri.https(_baseUrl, "products.json");
    final resp = await http.get(url);

    final Map<String, dynamic> productsMap = json.decode(resp.body);

    productsMap.forEach((key, value) {
      final tempProduct = Product.fromMap(value);
      tempProduct.id = key;
      products.add(tempProduct);
    });
    isLoading = false;
    notifyListeners();
  }

  /*Mètode que crida a un procés o un altre segons si el producte és nou o no*/
  Future saveOrCreateProduct(Product product) async {
    isSaving = true;
    notifyListeners();

    //Si el producte és nou
    if (product.id == null) {
      //Crear producte
      await createProduct(product);
    } else {
      //Actualitzar
      await updateProduct(product);
    }
    isSaving = false;
    notifyListeners();
  }

  /*Actualitza el producte de la base de dades l'api i de la llista de productes 
  segons el producte rebut per paràmetre. Utilitza PUT*/
  Future<String> updateProduct(Product product) async {
    final url = Uri.https(_baseUrl, "products/${product.id}.json");
    final resp = await http.put(url, body: product.toJson());
    final decodedData = resp.body;
    print(decodedData);

    final index =
        this.products.indexWhere((element) => element.id == product.id);
    this.products[index] = product;

    return product.id!;
  }

  /*Afegeix un nou producte a la base de dades de l'api i a la llista de
  productes. Utilitza POST*/
  Future<String> createProduct(Product product) async {
    final url = Uri.https(_baseUrl, "products.json");
    final resp = await http.post(url, body: product.toJson());
    final decodedData = json.decode(resp.body);
    //"Name" és l'id, no el nom del producte
    product.id = decodedData["name"];
    this.products.add(product);
    return product.id!;
  }

  //Crea un nou arxiu partint d'una ruta i actulitza l'imatge temporal del producte
  void updateSelectedImage(String path) {
    this.newPicture = File.fromUri(Uri(path: path));
    this.selectedProduct.picture = path;
    notifyListeners();
  }

  /*Mètode que ens retorna una URL vàlida que conté l'imatge que volem mostrar.
  Empram cloudinary per penjar l'imatge a la xarxa i retornam l'url per acceder-hi.
   */
  Future<String?> uploadImage() async {
    if (this.newPicture == null) return null;

    this.isSaving = true;
    notifyListeners();

    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/tcaldentey/image/upload?upload_preset=test-cloudinary");

    final imageUploadRequest = http.MultipartRequest("POST", url);
    final file = await http.MultipartFile.fromPath("file", newPicture!.path);

    imageUploadRequest.files.add(file);
    final streamResponse = await imageUploadRequest.send();

    final resp = await http.Response.fromStream(streamResponse);

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      print("Hi ha un error!");
      print(resp.body);
      return null;
    }

    this.newPicture = null;

    final decodeData = json.decode(resp.body);
    return decodeData["secure_url"];
  }
}
