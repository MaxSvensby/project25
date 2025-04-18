// var items = {
// 	simple: {
// 		skin: "M4A1-S | Cyrex",
// 		img: "https://steamcdn-a.akamaihd.net/apps/730/icons/econ/default_generated/weapon_m4a1_silencer_cu_m4a1s_cyrex_light_large.144b4053eb73b4a47f8128ebb0e808d8e28f5b9c.png"
// 	},
// 	middle: {
// 		skin: "M4A1-S | Chantico's Fire",
// 		img: "https://steamcommunity-a.akamaihd.net/economy/image/-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgpou-6kejhz2v_Nfz5H_uO1gb-Gw_alIITCmX5d_MR6j_v--YXygED6_UZrMTzwJYSdJlU8N1zY81TrxO_v0MW9uJnBm3Rk7nEk5XfUmEeyhQYMMLIUhCYx0A"
// 	},
// 	super: {
// 		skin: "M4A4 | Asiimov",
// 		img: "https://steamcdn-a.akamaihd.net/apps/730/icons/econ/default_generated/weapon_m4a1_cu_m4_asimov_light_large.af03179f3d43ff55b0c3d114c537eac77abdb6cf.png"
// 	}
// };
weapons_arr = weapons_arr.replace(/&quot;/g, '"').replace(/&gt;/g, '>');
weapons_arr = weapons_arr.replace(/"=>"/g, '":"').replace(/"=>/g, '":');

try {
	weapons = JSON.parse(weapons_arr); // Convert it into a proper JavaScript array
	
} catch (e) {
	console.error("Error parsing JSON:", e);
}

/* let items = []
for(var i = 0;i < 101; i++) {
	items.push({
		skin: weapons[i][1],
	})
} */
console.log(weapons)

document.getElementById("roll_case").addEventListener("click", () => {generate(1)});

function generate(ng) {
	console.log(weapons)
	$('.raffle-roller-container').css({
		transition: "sdf",
		"margin-left": "0px"
	}, 10).html('');
	for(var i = 0;i < 111; i++) {
		const index = i % weapons.length
		var element = '<div id="CardNumber'+i+'" class="item" style="background-image:url(/img/skins/'+ weapons[index]["collection"] +'/'+weapons[index]["name"]+'.png);"></div>';
		var randed = randomInt(1,1000);
		/* if(randed < 50) {
			element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		} else if(500 < randed) {
			element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		} */
		$(element).appendTo('.raffle-roller-container');
	}
	/* for(var i = 0;i < 101; i++) {
		var element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		var randed = randomInt(1,1000);
		if(randed < 50) {
			element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		} else if(500 < randed) {
			element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		}
		$(element).appendTo('.raffle-roller-container');
	} */
	
	setTimeout(function() {
		var rand = randomInt(40,100);
    	goRoll(rand, weapons[rand % weapons.length], '/img/skins/'+ weapons[rand % weapons.length]["collection"] +'/'+weapons[rand % weapons.length]["name"]+'.png')
	}, 500);
}
function goRoll(rand, skin, skinimg) {
	 console.log("rand", rand)
	$('.raffle-roller-container').css({
		transition: "all 8s cubic-bezier(.08,.6,0,1)"
	});
	$('#CardNumber'+rand).css({
		"background-image": "url("+skinimg+")"
	});
	setTimeout(function() {
		$('#CardNumber'+rand).addClass('winning-item');
		$('#rolled').html(skin[1]);
		sendClass(skin)
	}, 8500);
	$('.raffle-roller-container').css('margin-left', '-'+ (rand-4) * 5.75 +'rem'); //-425rem as math.random, (423,427)
}
function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min)) + min;
}

function sendClass(win_skin) {
	document.getElementById("popup-img").src = '/img/skins/'+ win_skin["collection"] +'/'+win_skin["name"]+'.png';
	document.getElementById("popup-item-name").innerText = win_skin["name"];

	document.getElementById("popup-overlay").classList.add("show");
	document.querySelector(".popup").classList.add("show");

    fetch('/items', {
        method: 'post',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'class_name=' + win_skin["id"]
    }).then(response => response.text()).then(data => {
        console.log(data);
    });
}

document.getElementById("close-btn").addEventListener("click", () => {closePopup()});

function closePopup() {
	document.getElementById("popup-overlay").classList.remove("show");
	document.querySelector(".popup").classList.remove("show");
}