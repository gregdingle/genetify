function test_Fspin(){
  var critical_F_table = [
    [161.4476,199.5000,215.7073,224.5832,230.1619,233.9860,236.7684,238.8827,240.5433,241.8817],
    [18.5128,19.0000,19.1643,19.2468,19.2964,19.3295,19.3532,19.3710,19.3848,19.3959],
    [10.1280,9.5521,9.2766,9.1172,9.0135,8.9406,8.8867,8.8452,8.8123,8.7855],
    [7.7086,6.9443,6.5914,6.3882,6.2561,6.1631,6.0942,6.0410,5.9988,5.9644],
    [6.6079,5.7861,5.4095,5.1922,5.0503,4.9503,4.8759,4.8183,4.7725,4.7351],
    [5.9874,5.1433,4.7571,4.5337,4.3874,4.2839,4.2067,4.1468,4.0990,4.0600],
    [5.5914,4.7374,4.3468,4.1203,3.9715,3.8660,3.7870,3.7257,3.6767,3.6365],
    [5.3177,4.4590,4.0662,3.8379,3.6875,3.5806,3.5005,3.4381,3.3881,3.3472],
    [5.1174,4.2565,3.8625,3.6331,3.4817,3.3738,3.2927,3.2296,3.1789,3.1373],
    [4.9646,4.1028,3.7083,3.4780,3.3258,3.2172,3.1355,3.0717,3.0204,2.9782]
  ];

  out = [];
  for (var i=0; i < critical_F_table.length; i++){
      var row = critical_F_table[i];
      for (var j=0; j < row.length; j++){
          var F = row[j];
          var df1 = j + 1;
          var df2 = i + 1;
          var p = Fspin(F, df1, df2);
          if (Math.round(p*1000)/1000 !== 0.05){
              throw('Test failed, p=='+p);
          }
          out.push(p);
      }
  }
  return out;
}
// adapted from http://faculty.vassar.edu/lowry/fcall.js
function Fspin(f, df1, df2) {
    var pj2 = Math.PI / 2;
    var x = df2 / (df1 * f + df2);
    if ((df1 % 2) == 0) {
        return LJspin(1 - x, df2, df1 + df2 - 4, df2 - 2) * Math.pow(x, df2 / 2)
    }
    if ((df2 % 2) == 0) {
        return 1 - LJspin(x, df1, df1 + df2 - 4, df1 - 2) * Math.pow(1 - x, df1 / 2)
    }
    var tan = Math.atan(Math.sqrt(df1 * f / df2));
    var a = tan / pj2;
    var sat = Math.sin(tan);
    var cot = Math.cos(tan);
    if (df2 > 1) {
        a = a + sat * cot * LJspin(cot * cot, 2, df2 - 3, -1) / pj2
    }
    if (df1 == 1) {
        return 1 - a
    }
    var c = 4 * LJspin(sat * sat, df2 + 1, df1 + df2 - 4, df2 - 2) * sat * Math.pow(cot, df2) / Math.PI;
    if (df2 == 1) {
        return 1 - a + c / 2
    }
    var k = 2;
    while (k <= (df2 - 1) / 2) {
        c = c * k / (k - .5);
        k = k + 1
    }
    return 1 - a + c;
}
function LJspin(q, i, j, b) {
    var zz = 1;
    var z = zz;
    var k = i;
    while (k <= j) {
        zz = zz * q * k / (k - b);
        z = z + zz;
        k = k + 2
    }
    return z
}

test_Fspin();
