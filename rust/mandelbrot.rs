use std::convert::TryInto;
use std::fs::File;
use std::io::Write;
use std::io;
use std::time::{SystemTime, UNIX_EPOCH};
//use std::env;

const WIDTH  : u32 = 1024;
const HEIGHT : u32 = 768;
const LENGTH : usize = WIDTH as usize * HEIGHT as usize;

const COLORS: [u32; 16] =
[
  0xff0000,  // f
  0xee3300,  // e
  0xcc5500,  // d
  0xaa5500,  // c
  0xaa3300,  // b
  0x666600,  // a
  0x999900,  // 9
  0x669900,  // 8
  0x339900,  // 7
  0x0099aa,  // 6
  0x0066aa,  // 5
  0x0033aa,  // 4
  0x0000aa,  // 3
  0x000099,  // 2
  0x000066,  // 1
  0x000000,  // 0
];

fn mandel_calc(
  picture: &mut [u32; LENGTH],
  width: u32,
  height: u32,
  real_start: f32,
  real_end: f32,
  imaginary_start: f32,
  imaginary_end: f32)
{
  const MAX_COUNT: u32 = 127;
  let (mut r, mut i): (f32, f32);
  let (mut tr, mut ti, mut zr, mut zi): (f32, f32, f32, f32);

  let r_step: f32 = (real_end - real_start) / width as f32;
  let i_step: f32 = (imaginary_end - imaginary_start) / height as f32;

  let mut count: u32 = 0;
  let mut ptr: usize = 0;

  i = imaginary_start;

  for _y in 0..height
  {
    r = real_start;

    for _x in 0..width
    {
      zr = 0.0;
      zi = 0.0;

      for c in 0..MAX_COUNT
      {
        tr = zr * zr - zi * zi;
        ti = 2.0 * zr * zi;
        zr = tr + r;
        zi = ti + i;

        if (zr * zr) + (zi * zi) > 4.0 { break; }
        count = c;
      }

      let index: usize = ((count >> 3) as usize).try_into().unwrap();
      picture[ptr] = COLORS[index];

      ptr += 1;
      r = r + r_step;
    }

    i = i + i_step;
  }
}

fn write_int16(out: &mut File, value: u32)
{
  let b0: u8 = (value & 0xff) as u8;
  let b1: u8 = ((value >> 8) & 0xff) as u8;

  let _ = out.write_all(&[b0, b1]);
}

fn write_int32(out: &mut File, value: u32)
{
  let b0: u8 = (value & 0xff) as u8;
  let b1: u8 = ((value >> 8)  & 0xff) as u8;
  let b2: u8 = ((value >> 16) & 0xff) as u8;
  let b3: u8 = ((value >> 24) & 0xff) as u8;

  let _ = out.write_all(&[b0, b1, b2, b3]);
}

fn write_bmp(picture: &mut [u32; LENGTH], width: u32, height: u32) -> Result<(), io::Error>
{
  let mut bmp_width: u32;
  let mut offset:    usize;
  let mut color:     u32;
  
  let mut out = File::create("out.bmp")?;

  bmp_width = width * 3;
  bmp_width = (bmp_width + 3) & (!0x3);

  let bmp_size: u32 = (bmp_width * height) + 14 + 40;
  let padding: u32 = bmp_width - (width * 3);

  // Size: 14 bytes.

  let _ = out.write_all(&[b'B']);
  let _ = out.write_all(&[b'M']);
  write_int32(&mut out, bmp_size);
  write_int16(&mut out, 0);
  write_int16(&mut out, 0);
  write_int32(&mut out, 54);

  // head1: 14  head2: 40.

  write_int32(&mut out, 40);         // biSize.
  write_int32(&mut out, width);
  write_int32(&mut out, height);
  write_int16(&mut out, 1);
  write_int16(&mut out, 24);
  write_int32(&mut out, 0);          // compression.
  write_int32(&mut out, bmp_width * height);
  write_int32(&mut out, 0);          // biXPelsperMetre.
  write_int32(&mut out, 0);          // biYPelsperMetre.
  write_int32(&mut out, 0);
  write_int32(&mut out, 0);

  for y in 0..height
  {
    offset = (y * width) as usize;

    for _x in 0..width
    {
      color = picture[offset];
      offset += 1;

      let _ = out.write_all(&[(color & 0xff) as u8]);
      let _ = out.write_all(&[((color >> 8) & 0xff) as u8]);
      let _ = out.write_all(&[((color >> 16) & 0xff) as u8]);
    }
    for _x in 0..padding { let _ = out.write_all(&[0]); }
  }

  Ok(())
}

fn main()
{
  let mut picture : [u32; LENGTH] = [0; LENGTH];

  //let args: Vec<String> = env::args().collect();

  let real_start:      f32 =  0.37 - 0.00;
  let real_end:        f32 =  0.37 + 0.04;
  let imaginary_start: f32 = -0.2166 - 0.02;
  let imaginary_end:   f32 = -0.2166 + 0.02;

  let start_time = SystemTime::now();

  mandel_calc(
    &mut picture,
    WIDTH,
    HEIGHT,
    real_start,
    real_end,
    imaginary_start,
    imaginary_end);

  let end_time = SystemTime::now();

  let milliseconds =
    end_time.duration_since(UNIX_EPOCH).expect("problem").as_millis() -
    start_time.duration_since(UNIX_EPOCH).expect("problem").as_millis();

  println!("time={}", milliseconds as f32 / 1000.0);

/*
  for _i in 0..100
  {
    picture[_i] = 0xffffff;

    let offset: usize = 400 * WIDTH as usize;
    picture[offset + _i] = 0xffffff;
  }
*/

  let _ = write_bmp(&mut picture, WIDTH, HEIGHT);

  println!("Done! {} {}", WIDTH, HEIGHT);
}

