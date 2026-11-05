return {
    photos = {
        provider = 'mysql',
        retakeOnIssue = false,
        cleanup = { intervalHours = 24, graceMinutes = 60 },
    },

    offerTime = 10000,

    tolerance = {
        view = 35.0,
        flash = 3.0,
        give = 2.5,
        handover = 3.0,
        keep = 10.0,
    },

    issuer = {
        state = 'SAN ANDREAS',
        country = 'USA',
        emblem = 'images/duck.png',
    },

    cards = {
        id_card = {
            label = 'State ID',
            title = 'IDENTIFICATION CARD',
            subtitle = 'STATE IDENTIFICATION',
            agency = 'Department of Motor Vehicles',
            theme = 'id',
            numberLabel = 'ID',
            prefix = 'S',
            years = 8,
            legal = 'This card is the property of the State of San Andreas and must be surrendered on demand. Altering this card is a crime.',
        },
        driver_license = {
            label = 'Driver License',
            title = 'DRIVER LICENSE',
            subtitle = 'NOT FOR FEDERAL PURPOSES',
            agency = 'Department of Motor Vehicles',
            theme = 'driver',
            numberLabel = 'DL',
            prefix = 'D',
            years = 5,
            class = 'C',
            legal = 'This license is the property of the State of San Andreas. It must be shown on demand of any peace officer. Altering this card is a crime.',
        },
        weaponlicense = {
            label = 'Weapon License',
            title = 'FIREARMS PERMIT',
            subtitle = 'CONCEALED CARRY',
            agency = 'Department of Justice',
            theme = 'weapon',
            numberLabel = 'PMT',
            prefix = 'W',
            years = 3,
            class = 'CCW',
            legal = 'Carry this permit with the licensed firearm at all times. It must be shown on demand of any peace officer.',
        },
        lawyerpass = {
            label = 'Lawyer Pass',
            title = 'BAR MEMBERSHIP',
            subtitle = 'ATTORNEY AT LAW',
            agency = 'State Bar',
            theme = 'lawyer',
            numberLabel = 'BAR',
            prefix = 'L',
            years = 2,
            legal = 'This pass identifies a member in good standing of the State Bar of San Andreas. It is not valid as proof of identity.',
        },
    },
}
