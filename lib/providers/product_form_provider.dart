import 'package:flutter/material.dart';
import 'package:productes_app/models/models.dart';

class ProductFormProvider extends ChangeNotifier {
  GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  Product tempProduct;

  ProductFormProvider(this.tempProduct);

  bool isValidForm() {
    print(tempProduct.name);
    print(tempProduct.price);
    print(tempProduct.available);
    return formKey.currentState?.validate() ?? false;
  }

  updateAvailability(bool value) {
    print(value);
    this.tempProduct.available = value;
    notifyListeners();
  }
}
