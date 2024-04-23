// config.js
const config = {
    idCardSettings: {
        closeKey: 'Backspace',
        autoClose: {
            status: false, // or true
            time: 3000
        }
    },
    licenses: {
        'id_card': {
            header: 'Identity',
            background: '#ebf7fd',            
            backgroundImage: 'https://i.ibb.co/vxvGzg1/card.png',
            prop: 'prop_franklin_dl'
        },
        'driver_license': {
            header: 'Driver License',
            background: '#febbbb',
            backgroundImage: 'https://i.ibb.co/vxvGzg1/card.png',
            prop: 'prop_franklin_dl',
        },
        'weaponlicense': {
            header: 'Weapon License',
            background: '#c7ffe5',
            backgroundImage: 'https://i.ibb.co/vxvGzg1/card.png',
            prop: 'prop_franklin_dl',
        },
        'lawyerpass': {
            header: 'Lawyer Pass',
            background: '#f9c491',
            backgroundImage: 'https://i.ibb.co/vxvGzg1/card.png',
            prop: 'prop_cs_r_business_card'
        }
    }
};

export default config;
