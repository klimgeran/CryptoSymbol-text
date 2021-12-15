// Crypto-Symbol-photo-text
// klimgeran, 2021, https://symbolplatform.ru/

import controlP5.*;
ControlP5 cp5;
Textarea debugArea;
String cryptPath="", refPath="", textPath="";
PImage imageCrypt, imageRef;
int imgWidth;

void setup() {
  size(700, 400);

  // GUI
  cp5 = new ControlP5(this);
  cp5.addButton("load_ref").setCaptionLabel("LOAD  PHOTO").setPosition(10, 10).setSize(120, 25);
  cp5.addButton("load_crypt_text").setCaptionLabel("LOAD  TEXT").setPosition(10, 40).setSize(120, 25);
  cp5.addButton("load_crypt").setCaptionLabel("LOAD  CRYPT  PHOTO").setPosition(10, 70).setSize(120, 25);
  cp5.addTextfield("key")
    .setPosition(10, 110)
    .setSize(120, 25)
    .setFont(createFont("arial", 15))
    .setAutoClear(false)
    .setCaptionLabel("")
    .setText("")
    ;
  cp5.addButton("encrypt").setCaptionLabel("ENCRYPT  AND  SAVE").setPosition(10, 140).setSize(120, 25);  
  cp5.addButton("decrypt").setCaptionLabel("DECRYPT").setPosition(10, 170).setSize(120, 25);

  debugArea = cp5.addTextarea("decryptText")
    .setPosition(120, 10)
    .setSize(575, 385)
    .setFont(createFont("arial", 17))
    .setLineHeight(19)
    .setColor(color(0))
    .setColorBackground(color(180))
    .setColorForeground(color(180));
  ;
  debugArea.setText("CryptoSymbol v2.0 by klimgeran");
}

void draw() {
}

// Get the seed from the encryption key
int getSeed() {  
  String thisKey = cp5.get(Textfield.class, "key").getText();
  int keySeed = 1;
  for (int i = 0; i < thisKey.length()-1; i++) 
    keySeed *= int(thisKey.charAt(i) * (thisKey.charAt(i)-thisKey.charAt(i+1)));  // multiplication with difference
  return keySeed;
}

// Encryption button
void encrypt() {
  if (refPath.length() != 0 && textPath.length() != 0) {
    // Uploading a photo to calculate its size
    imageCrypt = loadImage(refPath);
    imageCrypt.loadPixels();
    int imgSize = imageCrypt.width * imageCrypt.height;

    // Uploading a text to calculate its size
    String[] lines = loadStrings(textPath);    
    int textSize = 0;
    for (int i = 0; i < lines.length; i++) textSize += (lines[i].length() + 1);  //   

    // Possible mistakes
    if (textSize == 0) {
      debugArea.setText("Empty text file");
      return;
    }
    if (textSize >= imgSize) {
      debugArea.setText("Image is too small");
      return;
    }

    // Add zero to the very end of the text
    lines[lines.length-1] += '\0';
    textSize += 1;

    randomSeed(getSeed());

    // Variables
    int[] pixs = new int[textSize];  // Remembers the previous occupied pixels   
    int counter = 0;

    // Encryption cycle
    for (int i = 0; i < lines.length; i++) {         
      for (int j = 0; j < lines[i].length() + 1; j++) {

        // free pixel search
        int thisPix;
        while (true) {
          thisPix = (int)random(0, imgSize);         // choose random
          boolean check = true;                      // check flag
          for (int k = 0; k < counter; k++) {        // run through the previously selected pixels
            if (thisPix == pixs[k]) check = false;   // if the pixel is already occupied, omit the flag
          }
          if (check) {                               // pixel is free
            pixs[counter] = thisPix;                 // we store it in the buffer
            counter++;                               // ++
            break;                                   // leaving the cycle
          }
        }        
        
        int thisChar;
        if (j == lines[i].length()) thisChar = int('\n');  // line break
        else thisChar = lines[i].charAt(j);       // read the current character
        
        if (thisChar > 1000) thisChar -= 890;    // for Russian letters     

        int thisColor = imageCrypt.pixels[thisPix];  // read pixel

        // упаковка в RGB 323
        int newColor = (thisColor & 0xF80000);   // 11111000 00000000 00000000
        newColor |= (thisChar & 0xE0) << 11;     // 00000111 00000000 00000000
        newColor |= (thisColor & (0x3F << 10));  // 00000000 11111100 00000000
        newColor |= (thisChar & 0x18) << 5;      // 00000000 00000011 00000000
        newColor |= (thisColor & (0x1F << 3));   // 00000000 00000000 11111000
        newColor |= (thisChar & 0x7);            // 00000000 00000000 00000111

        imageCrypt.pixels[thisPix] = newColor;   // push it back into the picture
      }
    }
    imageCrypt.updatePixels();                   // update the photo
    imageCrypt.save("crypt_image.bmp");          // save
    debugArea.setText("Finished");
  } else debugArea.setText("Image is not selected");
}

// decryption button
void decrypt() {
  if (cryptPath.length() != 0) {
    // upload a photo and calculate its size
    imageCrypt = loadImage(cryptPath);
    imageCrypt.loadPixels();
    int imgSize = imageCrypt.width * imageCrypt.height;

    randomSeed(getSeed());

    int[] pixs = new int[imgSize];  // busy pixel buffer
    String decryptText = "";        // text buffer
    int counter = 0;

    // decryption cycle
    while (true) {

      // free pixel search same as above
      int thisPix;
      while (true) {    
        thisPix = (int)random(0, imgSize);
        boolean check = true;
        for (int k = 0; k < counter; k++) {
          if (thisPix == pixs[k]) check = false;
        }
        if (check) {
          pixs[counter] = thisPix;
          counter++;          
          break;
        }
      }

      // read pixel
      int thisColor = imageCrypt.pixels[thisPix];

      // распаковка из RGB 323 обратно в байт
      int thisChar = 0;
      thisChar |= (thisColor & 0x70000) >> 11;  // 00000111 00000000 00000000 -> 00000000 00000000 11100000
      thisChar |= (thisColor & 0x300) >> 5;     // 00000000 00000011 00000000 -> 00000000 00000000 00011000
      thisChar |= (thisColor & 0x7);            // 00000000 00000000 00000111

      if (thisChar > 130) thisChar += 890;      // crutch for Russian letters
      if (thisChar == 0) break;                 // the end of the text (we ourselves added this zero to the end).
      decryptText += char(thisChar);            // writing to the buffer
    }
    debugArea.setText(decryptText);            // 

    // save in txt
    String[] lines = new String[1];
    lines[0] = decryptText;
    saveStrings("decrypt_text.txt", lines);
  } else debugArea.setText("Crypted image is not selected");
}

// Additional buttons
void load_ref() {
  selectInput("", "selectRef");
}

void selectRef(File selection) {
  if (selection != null) {
    refPath = selection.getAbsolutePath();
    debugArea.setText(refPath);
  } else debugArea.setText("Image is not selected");
}

void load_crypt() {
  selectInput("", "selectCrypt");
}

void selectCrypt(File selection) {
  if (selection != null) {
    cryptPath = selection.getAbsolutePath();
    debugArea.setText(cryptPath);
  } else debugArea.setText("Crypted image is not selected");
}

void load_crypt_text() {
  selectInput("", "selectCryptText");
}

void selectCryptText(File selection) {
  if (selection != null) {
    textPath = selection.getAbsolutePath();
    debugArea.setText(textPath);
  } else debugArea.setText("Text file is not selected");
}
