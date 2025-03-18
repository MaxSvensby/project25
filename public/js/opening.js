var items = {
	simple: {
		skin: "M4A1-S | Cyrex",
		img: "https://steamcdn-a.akamaihd.net/apps/730/icons/econ/default_generated/weapon_m4a1_silencer_cu_m4a1s_cyrex_light_large.144b4053eb73b4a47f8128ebb0e808d8e28f5b9c.png"
	},
	middle: {
		skin: "M4A1-S | Chantico's Fire",
		img: "https://steamcommunity-a.akamaihd.net/economy/image/-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgpou-6kejhz2v_Nfz5H_uO1gb-Gw_alIITCmX5d_MR6j_v--YXygED6_UZrMTzwJYSdJlU8N1zY81TrxO_v0MW9uJnBm3Rk7nEk5XfUmEeyhQYMMLIUhCYx0A"
	},
	super: {
		skin: "M4A4 | Asiimov",
		img: "https://steamcdn-a.akamaihd.net/apps/730/icons/econ/default_generated/weapon_m4a1_cu_m4_asimov_light_large.af03179f3d43ff55b0c3d114c537eac77abdb6cf.png"
	}
};

function generate(ng) {
	$('.raffle-roller-container').css({
		transition: "sdf",
		"margin-left": "0px"
	}, 10).html('');
	for(var i = 0;i < 101; i++) {
		var element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		var randed = randomInt(1,1000);
		if(randed < 50) {
			element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		} else if(500 < randed) {
			element = '<div id="CardNumber'+i+'" class="item" style="background-image:url('+weapons.img+');"></div>';
		}
		$(element).appendTo('.raffle-roller-container');
	}
	setTimeout(function() {
    goRoll(weapons.skin, weapons.img)
	}, 500);
}
function goRoll(skin, skinimg) {
	$('.raffle-roller-container').css({
		transition: "all 8s cubic-bezier(.08,.6,0,1)"
	});
	$('#CardNumber78').css({
		"background-image": "url("+skinimg+")"
	});
	setTimeout(function() {
		$('#CardNumber78').addClass('winning-item');
		$('#rolled').html(skin);
	}, 8500);
	$('.raffle-roller-container').css('margin-left', '-6770px');
}
function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min)) + min;
}