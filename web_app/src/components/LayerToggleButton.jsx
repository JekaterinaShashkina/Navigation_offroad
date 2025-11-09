import { useState } from 'react'; 

export function LayerToggleButton({ layers, toggleLayer }) {
  // Hoiab nupu avatud/seisundi staatust
  const [open, setOpen] = useState(false);

  return (
    <div style={{
      position: 'absolute', // fikseeritud asukoht kaardil
      bottom: 150,
      right: 10.5,
      zIndex: 1000, // tagab, et nupp on peal teiste elementide
    }}>
      {/* Kihtide avamise/ sulgemise nupp */}
      <button
        onClick={() => setOpen(!open)} // vaheta avatud/seisundit
        style={{
          width: 39,
          height: 39,
          borderRadius: 24,
          backgroundColor: 'white',
          border: 'none',
          cursor: 'pointer',
          backgroundImage: 'url("https://img.icons8.com/ios-filled/50/layers.png")',
          backgroundSize: '60%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center',
        }}
      />
      
      {/* Kui nupp avatud, näita kihtide valikut */}
      {open && (
        <div style={{
          position: 'absolute',
          bottom: 30,
          right: 50,
          backgroundColor: 'white',
          padding: '10px 12px',
          borderRadius: 8,
          fontSize: 14,
          minWidth: 210,
        }}>
          {/* Kihtide valikud */}
          <label>
            <input
              type="checkbox"
              checked={layers.kaitseala} // kontrolli väärtus
              onChange={() => toggleLayer('kaitseala')} // kihtide lüliti
            /> Kaitseala
          </label>
          <br />
          <label>
            <input
              type="checkbox"
              checked={layers.hoiuala}
              onChange={() => toggleLayer('hoiuala')}
            /> Hoiuala
          </label>
          <br />
          <label>
            <input
              type="checkbox"
              checked={layers.keeluala}
              onChange={() => toggleLayer('keeluala')}
            /> Liikumispiirangud ja keelualad
          </label>
        </div>
      )}
    </div>
  );
}