class TraductorIA {
  static const Map<String, String> diccionario = {
    'person': 'Persona',
    'chair': 'Silla',
    'table': 'Mesa',
    'door': 'Puerta',
    'stair': 'Escaleras',
    'bottle': 'Botella',
    'cell phone': 'Teléfono celular',
    // Agrega aquí los objetos que mencionas en tu metodología de Word
  };

  static String traducir(String label) {
    return diccionario[label.toLowerCase()] ?? label;
  }
}