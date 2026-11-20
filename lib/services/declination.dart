import 'dart:math' as math;

/// Magnetic declination (the angle between Magnetic North and True North)
/// from the World Magnetic Model 2025 (NOAA/NCEI + British Geological
/// Survey), full degree 12, advanced to the given date with the model's
/// secular variation.
///
/// The model is pure Dart (no native library). Declination is computed
/// the standard WMM way: geodetic coordinates are converted to geocentric
/// spherical coordinates, Schmidt semi-normalized associated Legendre
/// functions give the field components, and the result is rotated back to
/// geodetic north/east/down. Declination is atan2(east, north): positive
/// means Magnetic North sits east of True North (as in most of the USA).
///
/// Coefficients are the official WMM2025 values (WMM.COF, epoch 2025.0),
/// columns n, m, g (nT), h (nT), g-dot (nT/year), h-dot (nT/year).
/// To move to a newer model (e.g. WMM2030), replace the numbers below —
/// the math stays the same.
class MagneticDeclination {
  static const _a = 6378.137; // WGS-84 semi-major axis, km.
  static const _f = 1 / 298.257223563; // WGS-84 flattening.
  static const _epoch = 2025.0;
  static const _maxDegree = 12;

  // n, m, g, h, gDot, hDot — WMM2025 main field, degrees 1..12.
  static const _coeffs = <List<double>>[
    [1, 0, -29351.8, 0.0, 12.0, 0.0],
    [1, 1, -1410.8, 4545.4, 9.7, -21.5],
    [2, 0, -2556.6, 0.0, -11.6, 0.0],
    [2, 1, 2951.1, -3133.6, -5.2, -27.7],
    [2, 2, 1649.3, -815.1, -8.0, -12.1],
    [3, 0, 1361.0, 0.0, -1.3, 0.0],
    [3, 1, -2404.1, -56.6, -4.2, 4.0],
    [3, 2, 1243.8, 237.5, 0.4, -0.3],
    [3, 3, 453.6, -549.5, -15.6, -4.1],
    [4, 0, 895.0, 0.0, -1.6, 0.0],
    [4, 1, 799.5, 278.6, -2.4, -1.1],
    [4, 2, 55.7, -133.9, -6.0, 4.1],
    [4, 3, -281.1, 212.0, 5.6, 1.6],
    [4, 4, 12.1, -375.6, -7.0, -4.4],
    [5, 0, -233.2, 0.0, 0.6, 0.0],
    [5, 1, 368.9, 45.4, 1.4, -0.5],
    [5, 2, 187.2, 220.2, 0.0, 2.2],
    [5, 3, -138.7, -122.9, 0.6, 0.4],
    [5, 4, -142.0, 43.0, 2.2, 1.7],
    [5, 5, 20.9, 106.1, 0.9, 1.9],
    [6, 0, 64.4, 0.0, -0.2, 0.0],
    [6, 1, 63.8, -18.4, -0.4, 0.3],
    [6, 2, 76.9, 16.8, 0.9, -1.6],
    [6, 3, -115.7, 48.8, 1.2, -0.4],
    [6, 4, -40.9, -59.8, -0.9, 0.9],
    [6, 5, 14.9, 10.9, 0.3, 0.7],
    [6, 6, -60.7, 72.7, 0.9, 0.9],
    [7, 0, 79.5, 0.0, -0.0, 0.0],
    [7, 1, -77.0, -48.9, -0.1, 0.6],
    [7, 2, -8.8, -14.4, -0.1, 0.5],
    [7, 3, 59.3, -1.0, 0.5, -0.8],
    [7, 4, 15.8, 23.4, -0.1, 0.0],
    [7, 5, 2.5, -7.4, -0.8, -1.0],
    [7, 6, -11.1, -25.1, -0.8, 0.6],
    [7, 7, 14.2, -2.3, 0.8, -0.2],
    [8, 0, 23.2, 0.0, -0.1, 0.0],
    [8, 1, 10.8, 7.1, 0.2, -0.2],
    [8, 2, -17.5, -12.6, 0.0, 0.5],
    [8, 3, 2.0, 11.4, 0.5, -0.4],
    [8, 4, -21.7, -9.7, -0.1, 0.4],
    [8, 5, 16.9, 12.7, 0.3, -0.5],
    [8, 6, 15.0, 0.7, 0.2, -0.6],
    [8, 7, -16.8, -5.2, -0.0, 0.3],
    [8, 8, 0.9, 3.9, 0.2, 0.2],
    [9, 0, 4.6, 0.0, -0.0, 0.0],
    [9, 1, 7.8, -24.8, -0.1, -0.3],
    [9, 2, 3.0, 12.2, 0.1, 0.3],
    [9, 3, -0.2, 8.3, 0.3, -0.3],
    [9, 4, -2.5, -3.3, -0.3, 0.3],
    [9, 5, -13.1, -5.2, 0.0, 0.2],
    [9, 6, 2.4, 7.2, 0.3, -0.1],
    [9, 7, 8.6, -0.6, -0.1, -0.2],
    [9, 8, -8.7, 0.8, 0.1, 0.4],
    [9, 9, -12.9, 10.0, -0.1, 0.1],
    [10, 0, -1.3, 0.0, 0.1, 0.0],
    [10, 1, -6.4, 3.3, 0.0, 0.0],
    [10, 2, 0.2, 0.0, 0.1, -0.0],
    [10, 3, 2.0, 2.4, 0.1, -0.2],
    [10, 4, -1.0, 5.3, -0.0, 0.1],
    [10, 5, -0.6, -9.1, -0.3, -0.1],
    [10, 6, -0.9, 0.4, 0.0, 0.1],
    [10, 7, 1.5, -4.2, -0.1, 0.0],
    [10, 8, 0.9, -3.8, -0.1, -0.1],
    [10, 9, -2.7, 0.9, -0.0, 0.2],
    [10, 10, -3.9, -9.1, -0.0, -0.0],
    [11, 0, 2.9, 0.0, 0.0, 0.0],
    [11, 1, -1.5, 0.0, -0.0, -0.0],
    [11, 2, -2.5, 2.9, 0.0, 0.1],
    [11, 3, 2.4, -0.6, 0.0, -0.0],
    [11, 4, -0.6, 0.2, 0.0, 0.1],
    [11, 5, -0.1, 0.5, -0.1, -0.0],
    [11, 6, -0.6, -0.3, 0.0, -0.0],
    [11, 7, -0.1, -1.2, -0.0, 0.1],
    [11, 8, 1.1, -1.7, -0.1, -0.0],
    [11, 9, -1.0, -2.9, -0.1, 0.0],
    [11, 10, -0.2, -1.8, -0.1, 0.0],
    [11, 11, 2.6, -2.3, -0.1, 0.0],
    [12, 0, -2.0, 0.0, 0.0, 0.0],
    [12, 1, -0.2, -1.3, 0.0, -0.0],
    [12, 2, 0.3, 0.7, -0.0, 0.0],
    [12, 3, 1.2, 1.0, -0.0, -0.1],
    [12, 4, -1.3, -1.4, -0.0, 0.1],
    [12, 5, 0.6, -0.0, -0.0, -0.0],
    [12, 6, 0.6, 0.6, 0.1, -0.0],
    [12, 7, 0.5, -0.1, -0.0, -0.0],
    [12, 8, -0.1, 0.8, 0.0, 0.0],
    [12, 9, -0.4, 0.1, 0.0, -0.0],
    [12, 10, -0.2, -1.0, -0.1, -0.0],
    [12, 11, -1.3, 0.1, -0.0, 0.0],
    [12, 12, -0.7, 0.2, -0.1, -0.1],
  ];

  /// Declination in degrees, positive east of True North.
  ///
  /// [latitude] and [longitude] are geodetic degrees. [date] defaults to
  /// now; pass a fixed date in tests so the answer never drifts.
  static double declination({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final t = _decimalYear(now);
    final dt = t - _epoch;

    final lat = latitude * math.pi / 180;
    final lon = longitude * math.pi / 180;

    // Geodetic -> geocentric spherical coordinates (height 0).
    final e2 = _f * (2 - _f);
    final sinLat = math.sin(lat);
    final cosLat = math.cos(lat);
    final primeVertical =
        _a / math.sqrt(1 - e2 * sinLat * sinLat); // N, km.
    final r = math.sqrt(
      primeVertical * primeVertical * cosLat * cosLat +
          (1 - e2) * (1 - e2) * primeVertical * primeVertical * sinLat * sinLat,
    );
    final sinLatC = (1 - e2) * primeVertical * sinLat / r;
    final latC = math.asin(sinLatC.clamp(-1.0, 1.0));
    final theta = math.pi / 2 - latC; // Colatitude.
    final x = math.cos(theta);
    final s = math.sin(theta);

    final legendre = _schmidtLegendre(x, s, _maxDegree);

    var br = 0.0; // Radial (out).
    var bt = 0.0; // Theta (south).
    var bp = 0.0; // Phi (east).
    for (final c in _coeffs) {
      final n = c[0].toInt();
      final m = c[1].toInt();
      final g = c[2] + c[4] * dt;
      final h = c[3] + c[5] * dt;
      final p = legendre['p']![n]![m]!;
      final dp = legendre['d']![n]![m]!;
      final cosMLambda = math.cos(m * lon);
      final sinMLambda = math.sin(m * lon);
      final common = g * cosMLambda + h * sinMLambda;
      final factor = math.pow(_a / r, n + 2);
      br += (n + 1) * factor * common * p;
      bt += -factor * common * dp;
      if (m > 0 && s.abs() > 1e-9) {
        bp += factor * m * (g * sinMLambda - h * cosMLambda) * p / s;
      }
    }

    // Rotate spherical components back to geodetic north/east/down.
    // (WMM geomag.c: X = -Br sin(alpha) - Btheta cos(alpha), where
    // alpha = geodetic latitude - geocentric latitude.)
    final alpha = lat - latC;
    final sinAlpha = math.sin(alpha);
    final cosAlpha = math.cos(alpha);
    final north = -br * sinAlpha - bt * cosAlpha;
    final east = bp;

    return math.atan2(east, north) * 180 / math.pi;
  }

  static double _decimalYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final next = DateTime(date.year + 1, 1, 1);
    final yearLength = next.difference(start).inMilliseconds;
    final elapsed = date.difference(start).inMilliseconds;
    return date.year + elapsed / yearLength;
  }

  /// Schmidt semi-normalized associated Legendre functions P(n,m) and
  /// their derivatives with respect to colatitude theta, for n <= [maxN].
  ///
  /// Built from the exact sum formula for the derivatives of the Legendre
  /// polynomials, so the values match the WMM convention (no
  /// Condon-Shortley phase). Returns {'p': {n: {m: value}},
  /// 'd': {n: {m: derivative}}}. x = cos(theta), s = sin(theta).
  static Map<String, Map<int, Map<int, double>>> _schmidtLegendre(
    double x,
    double s,
    int maxN,
  ) {
    // m-th derivative of the Legendre polynomial P_n at x, from the
    // explicit sum: P_n(x) = sum_k (-1)^k (2n-2k)! / (2^n k! (n-k)!
    // (n-2k)!) * x^(n-2k).
    double dLegendre(int n, int m) {
      var sum = 0.0;
      for (var k = 0; k <= n ~/ 2; k++) {
        final nMinus2k = n - 2 * k;
        if (nMinus2k < m) continue;
        final sign = k.isEven ? 1.0 : -1.0;
        final coeff = sign *
            _factorial(2 * n - 2 * k) /
            (math.pow(2, n).toDouble() *
                _factorial(k) *
                _factorial(n - k) *
                _factorial(nMinus2k));
        final deriv = _factorial(nMinus2k) / _factorial(nMinus2k - m);
        sum += coeff * deriv * math.pow(x, nMinus2k - m).toDouble();
      }
      return sum;
    }

    // Schmidt factor S(n,m) = sqrt((2 - d_m0) * (n-m)! / (n+m)!).
    double schmidt(int n, int m) {
      final factor = m == 0 ? 1.0 : 2.0;
      return math.sqrt(factor * _factorial(n - m) / _factorial(n + m));
    }

    final p = <int, Map<int, double>>{};
    final d = <int, Map<int, double>>{};
    for (var n = 0; n <= maxN; n++) {
      p[n] = {};
      d[n] = {};
      for (var m = 0; m <= n; m++) {
        final sn = schmidt(n, m);
        final dm = dLegendre(n, m);
        final value = sn * math.pow(s, m).toDouble() * dm;
        p[n]![m] = value;
        // dP/dθ: for m = 0, -s * D^1 P_n; for m >= 1,
        // S * s^(m-1) * (m x D^m P_n - s^2 D^(m+1) P_n).
        if (m == 0) {
          d[n]![m] = -s * dLegendre(n, 1);
        } else if (s.abs() < 1e-9) {
          d[n]![m] = 0.0;
        } else {
          final dm1 = dLegendre(n, m + 1);
          d[n]![m] = sn *
              math.pow(s, m - 1).toDouble() *
              (m * x * dm - s * s * dm1);
        }
      }
    }
    return {'p': p, 'd': d};
  }

  static double _factorial(int n) {
    var result = 1.0;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}
