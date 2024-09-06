part of '../../ml_card_scanner.dart';

class CardParserUtil {
  final int _cardNumberLength = 16;
  final String _cardVisa = 'Visa';
  final String _cardMasterCard = 'MasterCard';
  final String _cardUnknown = 'Unknown';
  final String _cardVisaParam = '4';
  final String _cardMasterCardParam = '5';

  Future<CardInfo?> detectCardContent(String data,) async {
    try {
      // var input = await _textDetector.processImage(inputImage);

      // var clearElements = input.blocks.map((e) => e.text.clean()).toList();

      // var possibleCardNumber = clearElements.firstWhere((input) {
      //   final cleanValue = input.fixPossibleMisspells();
      //   return (cleanValue.length == _cardNumberLength) &&
      //       (int.tryParse(cleanValue) ?? -1) != -1;
      // });
      // var cardType = _getCardType(possibleCardNumber);
      // var expire = _getExpireDate(clearElements);
      // return CardInfo(
      //     number: possibleCardNumber, type: cardType, expiry: expire);

      if (Platform.isIOS) {
        print('debug-print detectCardContent on iOS');
        // File file = File(inputImage.filePath ?? '');
        // print('path: ${inputImage.filePath}');
        // if (!file.existsSync()) {
        //   print('debug-print file does not exist');
        //   return null;
        // }
        // final Uint8List bytes = await file.readAsBytes();
        final ocrResult = await AppleOcr.getTextFromImage(data);
        print('result');
        final String cardNumber = AppleOcr.getCardNumber(ocrResult);
        final String expiryDate = AppleOcr.getExpiryDate(ocrResult);
        print('debug-print cardNumber = $cardNumber');
        print('debug-print expiryDate = $expiryDate');
        return CardInfo(
          number: cardNumber,
          type: '',
          expiry: expiryDate,
        );
      } else {
        return null;
      }
    } catch (e, _) {
      return null;
    }
  }

  String _getExpireDate(List<String> input) {
    try {
      final possibleDate = input.firstWhere((input) {
        final cleanValue = input.fixPossibleMisspells();
        if (cleanValue.length == 4) {
          return true;
        }
        return false;
      });
      return possibleDate.fixPossibleMisspells().possibleDateFormatted();
    } catch (e, _) {
      return '';
    }
  }

  String _getCardType(String input) {
    if (input[0] == _cardVisaParam) {
      return _cardVisa;
    }
    if (input[0] == _cardMasterCardParam) {
      return _cardMasterCard;
    }
    return _cardUnknown;
  }
}
