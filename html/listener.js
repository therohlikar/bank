var accounts = null;
var inMachine = false;
var inMachineAccount = null;

var currentPermissions = null;
var currentAccount = 0;
var currentInvoice = 0;
var currentAccess = 0;
var currentCard = 0;
var currentFine = 0;

var settings = null;

var fullPermissions = {
	balance : true, 
	withdraw_take : true,  
	withdraw_put : true,  
	transfer : true,  
	changetype : true, 
	changeowner : true,  
	changename : true, 
	access : true, 
	invoices : true, 
	payinvoice : true,
	delete : true,
	cards : true
}

var defaultPermissions = {
	balance : true, 
	withdraw_take : true,  
	withdraw_put : true,  
	transfer : true,  
	changetype : false, 
	changeowner : false,  
	changename : false, 
	access : false, 
	invoices : true, 
	payinvoice : false,
	delete : false,
	cards : false
}

document.onkeyup = function (data) {
    if (data.which == 27) { closepanel(); }
};

$(function () {
	window.addEventListener('message', function (event) {
		switch (event.data.action) {
			case 'show-machine':
				$('#box').show();
				inMachine = true;

				currentCard = event.data.cardId;
				currentAccount = event.data.account.number;
				inMachineAccount = event.data.account;
				settings = event.data.settings;
				currentPermissions = fullPermissions;

				openmenu("cash-machine");
				opencontent('cashmachine-login');	
				break;
			case 'hide-machine':
				inMachine = false;
				$('#box').hide();
				break;
			case 'show':
				$('#box').show();	
				inMachine = false;

				currentAccount = 0;
				accounts = event.data.accounts;
				settings = event.data.settings;

				openmenu("main");
				opencontent('accountlist');		
				break;
			case 'hide':
				$('#box').hide();
				break;
			case 'updateaccounts':
				accounts = event.data.accounts;
				break;
			case 'updateaccount':
				if(!inMachine) accounts[event.data.account.number] = event.data.account;
				else inMachineAccount = event.data.account;

				/* sync values which can be changed */
				update(event.data.account);
				break;
			case 'updatepersonalinvoices':
				accounts.personalinvoices = event.data.data;
				break;
			case 'updatefines':
				accounts.fines = event.data.data;
				break;
			case 'updatejob':
				settings.job = event.data.job;

				if(currentAccount != 0){
					if(accounts[currentAccount].access_list.job.name != "none" && accounts[currentAccount].founder.id != settings.charId){
						if(accounts[currentAccount].access_list.job.name != settings.job.name || accounts[currentAccount].access_list.job.grade > settings.job.grade){
							var found = false;
							for(var i = 0; i < accounts[currentAccount].access_list.users.length; i++){
								if(accounts[currentAccount].access_list.users[i].id == charId){
									found = true;
									break;
								}
							}

							if(!found){
								closepanel();
							}
						}
					}
				}
				break;
			default:
				console.log('ui_bank: unknown action!');
				break;
		}
	}, false);
});

function rename(){
	if($('#input-text').val() == "" || $('#input-text').val().length > 50) return; 

	$.post("http://bank/action", JSON.stringify({
		action: "rename",
		account: currentAccount,
		value: $('#input-text').val()
	}));
}

function withdraw(action){
	if($('#input-number').val() <= 0) return; 

	$.post("http://bank/action", JSON.stringify({
		action: action,
		account: currentAccount,
		value: $('#input-number').val()
	}));

	$('#input-number').val('');
}

function transfer(){
	if($('#input-number').val() <= 0) return; 
	if($('#input-text').val() == "") return; 

	$.post("http://bank/action", JSON.stringify({
		action: "transfer",
		account: currentAccount,
		target: $('#input-text').val(),
		value: $('#input-number').val()
	}));

	$('#input-number').val(0);
	$('#input-text').val("");
}

function setpermissions(index){
	if(accounts[index].founder.id != null && accounts[index].founder.id == settings.charId){
		currentPermissions = fullPermissions
	}else{
		for(var i = 0; i < accounts[index].access_list.users.length; i++){
			if(accounts[index].access_list.users[i].id == settings.charId){
				currentPermissions = defaultPermissions
				if(accounts[index].access_list.users[i].permissions != null){
					currentPermissions = accounts[index].access_list.users[i].permissions
				}
				break;
			}
		}
	}
}

function update(account){
	var number = account.number;
	$('.balance-' + number).html("$" + account.balance);
	$('.description-' + number).html(account.description);
	$('.founder-' + number).html(account.founder.name);
	var accounttype = "OSOBNÍ ÚČET";
	if(account.access_list.job.name != "none"){
		accounttype = "FIREMNÍ ÚČET [" + account.access_list.job.name + "]";
	}
	$('.type-' + number).html(accounttype);
}

function refreshiconsbyperms(){
	if(currentPermissions.transfer) $('#transfers').show();
	else $('#transfers').hide();

	if(currentPermissions.balance) $('#information').show();
	else $('#information').hide();

	if(currentPermissions.invoices) $('#invoices').show();
	else $('#invoices').hide();

	if(currentPermissions.access) $('#access').show();
	else $('#access').hide();

	if(currentPermissions.cards) $('#cards').show();
	else $('#cards').hide();

	if(currentPermissions.withdraw_take || currentPermissions.withdraw_put) $('#cash').show();
	else if(!currentPermissions.withdraw_take && !currentPermissions.withdraw_put) $('#cash').hide();
}

function selectaccount(index){
	setpermissions(index);
	currentAccount = index;
	refreshiconsbyperms();
	openmenu("account");
	opencontent("information");
}

function selectaccess(index){
	currentAccess = index;
	opencontent("access-select");
}

function createaccount(){
	if(selectedtype != null){
		$.post("http://bank/action", JSON.stringify({
			action: "createaccount",
			type: selectedtype
		}));
		closepanel();
	}
}

function changetype(){
	if(selectedtype != null){
		$.post("http://bank/action", JSON.stringify({
			action: "changetype",
			account: currentAccount,
			type: selectedtype
		}));
	}
}

function deleteaccount(){
	$.post("http://bank/action", JSON.stringify({
		action: "delete",
		account: currentAccount
	}));
	closepanel()
}

function addaccess(){
	$.post("http://bank/action", JSON.stringify({
		action: "access-add",
		account: currentAccount
	}));
	closepanel()
}

function removeaccess(controlid){
	if(accounts[currentAccount].access_list.users[currentAccess].id != controlid) return;

	$.post("http://bank/action", JSON.stringify({
		action: "access-remove",
		target: controlid,
		account: currentAccount
	}));
	opencontent('information');
}

function changefounder(){
	$.post("http://bank/action", JSON.stringify({
		action: "changefounder",
		account: currentAccount
	}));
	closepanel()
}

function selectinvoice(index){
	currentInvoice = index;
	opencontent("selected-invoice")
}

function selectfine(index){
	currentFine = index;
	opencontent("payfine")
}

function createcard(){
	if($('#input-text').val() == "") return; 

	$.post("http://bank/action", JSON.stringify({
		action: "createcard",
		account: currentAccount,
		code: $('#input-text').val()
	}));

	$('#input-text').val("");
	opencontent('information');
}

var selectedtype = "company";
function selecttype(selected){
	selectedtype = selected;
	if(selected == "company"){
		$('.companytype').addClass('lighter');
		$('.personaltype').removeClass('lighter');
	}else{
		$('.personaltype').addClass('lighter');
		$('.companytype').removeClass('lighter');
	}
}

function selectcard(selected){
	currentCard = selected;
	opencontent('card-select');
}

function blockcard(action){
	$.post("http://bank/action", JSON.stringify({
		action: "blockcard",
		type: action,
		account: currentAccount,
		card: currentCard
	}));
	
	opencontent('cards');
}

function deletecard(){
	$.post("http://bank/action", JSON.stringify({
		action: "deletecard",
		account: currentAccount,
		card: currentCard
	}));
	
	opencontent('information');
}

function renamecard(){
	if($('#input-text').val() == "") return; 

	$.post("http://bank/action", JSON.stringify({
		action: "renamecard",
		account: currentAccount,
		card: currentCard,
		name: $('#input-text').val()
	}));

	$('#input-text').val("");
	opencontent('information');
}

function logincard(){
	if($('#input-text').val() == "") return; 

	if($('#input-text').val() == inMachineAccount.cards[currentCard].code) opencontent("cash-machine");
	else notify("warning", "Platební karta", "Přihlášení proběhlo neúspěšně.");

	$('#input-text').val("");
}

function setinvoicepaid(invoiceId){
	$.post("http://bank/action", JSON.stringify({
		action: "setinvoicepaid",
		account: currentAccount,
		invoiceId: invoiceId
	}));
	closepanel();
}

function selectunpersonalinvoice(invoiceId){
	currentInvoice = invoiceId
	opencontent("payinvoice");
}

function opencontent(name){
	if(name == "accountlist"){
		openmenu("main");

		$('#content').html('<ul>');
		var count = 0;
		$.each(accounts, function(key, value) {
			if(key != 'personalinvoices' && key != 'fines'){
				count++;
				var accounttype = "OSOBNÍ ÚČET";
				if(accounts[key].access_list.job.name != "none"){
					accounttype = "FIREMNÍ ÚČET";
				}
				$('#content').append("<li onclick='selectaccount(" + key + ")' class='list-point activate'><span class='to-the-left type-" + key + "'>" + accounttype + ": " + key + "</span><span class='in-the-middle description-"+ key + "'>" + accounts[key].description + "</span></span></li>");
			}
		});

		if(count<=0){
			$('#content').append("<li onclick=\"opencontent('newaccount')\" class='list-point activate'>NEMÁTE ŽÁDNÝ DOSTUPNÝ ÚČET</li>");
		}
		
		$('#content').append('</ul>');
	}else if(name == "newaccount"){
		openmenu("main");

		if(settings.count >= settings.maxAccounts){
			$('#content').html("<div onclick=\"opencontent('accountlist')\" class='list-point red-activate'>SPRAVUJETE JIŽ MAXIMÁLNÍ MNOŽSTVÍ ÚČTŮ</div>");
		}else{
			selecttype("company");
			$('#content').html("<div class='list-point'>Zvolte typ účtu:</div><div onclick=\"selecttype('company')\" class='list-point shorter activate lighter companytype'>FIREMNÍ [" + settings.job.name + "]</div><div onclick=\"selecttype('personal')\" class='list-point shorter activate personaltype'>OSOBNÍ</div>");
			$('#content').append("<div onclick=\"createaccount()\" class='list-point activate'>Otevřít nový účet</div>");
		}
	}else if(name == "information"){
		var accounttype = "OSOBNÍ ÚČET";
		if(accounts[currentAccount].access_list.job.name != "none"){
			accounttype = "FIREMNÍ ÚČET [" + accounts[currentAccount].access_list.job.name + "]";
		}
		$('#content').html("<div onclick=\"copyToClipboard(accountnumber)\" class='list-point activate'>Číslo účtu: <span class='to-the-right' id='accountnumber'>" + currentAccount + "</span></div>");
		$('#content').append("<div onclick=\"opencontent('edit_type')\" class='list-point activate'>Typ účtu: <span class='to-the-right type-" + currentAccount + "'>" + accounttype + "</span></div>");
		if(currentPermissions.balance){
			$('#content').append("<div class='list-point'>Aktuální stav účtu: <span class='to-the-right balance-" + currentAccount + "'>$" + accounts[currentAccount].balance + "</span></div>");
		}
		$('#content').append("<div onclick=\"opencontent('edit_description')\" class='list-point activate'>Název účtu: <span class='to-the-right description-" + currentAccount + "'>" + accounts[currentAccount].description + "</span></div>");
		$('#content').append("<div onclick=\"changefounder()\" class='list-point activate'>Správce účtu: <span class='to-the-right founder-" + currentAccount + "'>" + accounts[currentAccount].founder.name + "</span></div>");
		if(currentPermissions.delete){
			$('#content').append("<div onclick=\"opencontent('delete')\" class='list-point red-activate'>Permanentně smazat účet</div>");
		}
	}else if(name == "transfers"){
		if(currentPermissions.transfer){
			$('#content').html("");
			if(currentPermissions.balance){
				$('#content').append("<div class='list-point'>Aktuální stav účtu: <span class='balance-" + currentAccount + "'>$" + accounts[currentAccount].balance + "</span></div>");
			}
			$('#content').append("<div class='block'><input type='text' id='input-text' placeholder='Protiúčet' maxlength='10'><input type='number' id='input-number' value='0' min='0'><button onclick='transfer()' class='activate' type='submit' id='btn-withdraw-put'>Zpracovat platbu</button></div>");
		}else notify("warning", "Narazili jsme na chybu", "Bohužel nemáte dostatečná oprávnění.");
	}else if(name == "delete"){
		if(currentPermissions.delete){
			$('#content').html("<div onclick=\"opencontent('information')\" class='list-point activate'>Ponechat účet</div><div onclick=\"deleteaccount()\" class='list-point red-activate'>Permatnentně smazat účet</div>");
		}else notify("warning", "Narazili jsme na chybu", "Bohužel nemáte dostatečná oprávnění.");
	}else if(name == "cash"){
		$('#content').html("");
		if(currentPermissions.balance){
			$('#content').append("<div class='list-point'>Aktuální stav účtu: <span class='balance-" + currentAccount + "'>$" + accounts[currentAccount].balance + "</span></div>");
		}
		$('#content').append("<div class='block'><input type='number' id='input-number' placeholder='0' min='0'><button onclick='withdraw(\"withdraw-put\")' class='activate' type='submit' id='btn-withdraw-put'>Vložit peníze na účet</button><button onclick='withdraw(\"withdraw-take\")' class='activate' type='submit' id='btn-withdraw-take'>Vybrat peníze z účtu</button></div>");
		if(currentPermissions.withdraw_put) $('#btn-withdraw-put').show();
		else $('#btn-withdraw-put').hide();

		if(currentPermissions.withdraw_take) $('#btn-withdraw-take').show();
		else $('#btn-withdraw-take').hide();
	}else if(name == "edit_description"){
		if(currentPermissions.changename){
			$('#content').html("<div class='list-point'>Aktuální název účtu: <span class='description-" + currentAccount + "'>" + accounts[currentAccount].description + "</span></div><div class='block'><input type='text' id='input-text' value='" + accounts[currentAccount].description + "'><button onclick=\"rename()\" class='activate' type='submit' id='btn-rename'>Přejmenovat účet</button></div>");
		}else notify("warning", "Narazili jsme na chybu", "Bohužel nemáte dostatečná oprávnění.");
	}else if(name == "edit_type"){
		if(currentPermissions.changetype){
			var accounttype = "OSOBNÍ ÚČET";
			if(accounts[currentAccount].access_list.job.name != "none"){
				accounttype = "FIREMNÍ ÚČET [" + accounts[currentAccount].access_list.job.name + "]";
			}
			$('#content').html("<div class='list-point'>Aktuální typ účtu: <span class='type-" + currentAccount + "'>" + accounttype + "</span></div>");
			$('#content').append("<div class='list-point'>Zvolte typ účtu:</div><div onclick=\"selecttype('company')\" class='list-point shorter activate lighter companytype'>FIREMNÍ [" + settings.job.name + "]</div><div onclick=\"selecttype('personal')\" class='list-point shorter activate personaltype'>OSOBNÍ</div>");
			$('#content').append("<div onclick=\"changetype()\" class='list-point activate'>Zpracovat požadavek na změnu typu</div>");
		}else notify("warning", "Narazili jsme na chybu", "Bohužel nemáte dostatečná oprávnění.");
	}else if(name == "invoices"){
		$('#content').html("<div onclick=\"opencontent('invoices-unpayed')\" class='list-point red-activate'>NEZAPLACENÉ FAKTURY</div>");
		$('#content').append("<div onclick=\"opencontent('invoices-payed')\" class='list-point activate '>ZAPLACENÉ FAKTURY</div>");
	}else if(name == "invoices-payed"){
		var count = 0;
		$('#content').html("");
		$.each(accounts[currentAccount].invoices, function(key, value) {
			if(accounts[currentAccount].invoices[key].payed > 0){
				count++;
				$('#content').append("<div onclick=\"selectinvoice('" + key + "')\" class='list-point activate'><span class='to-the-left'>" + accounts[currentAccount].invoices[key].id + "</span><span class='in-the-middle'>$" + accounts[currentAccount].invoices[key].price + "</span><span class='to-the-right'>" + accounts[currentAccount].invoices[key].ownerlabel + "</span></div>");
			}
		});

		if(count<=0){
			$('#content').html("<div class='list-point'>ŽÁDNÉ ZAPLACENÉ FAKTURY</div>");
		}
	}else if(name == "invoices-unpayed"){
		var count = 0;
		$('#content').html("");
		$.each(accounts[currentAccount].invoices, function(key, value) {
			if(accounts[currentAccount].invoices[key].payed <= 0){
				count++;
				$('#content').append("<div onclick=\"selectinvoice('" + key + "')\" class='list-point red-activate'><span class='to-the-left'>" + accounts[currentAccount].invoices[key].id + "</span><span class='in-the-middle'>$" + accounts[currentAccount].invoices[key].price + "</span><span class='to-the-right'>" + accounts[currentAccount].invoices[key].ownerlabel + "</span></div>");
			}
		});

		if(count<=0){
			$('#content').html("<div class='list-point red-point'>ŽÁDNÉ NEZAPLACENÉ FAKTURY</div>");
		}
	}else if(name == "selected-invoice"){
		if(accounts[currentAccount].invoices[currentInvoice].payed <= 0){
			$('#content').html("<div class='list-point red-point'>NEZAPLACENO</div>");
		}else{
			$('#content').html("<div class='list-point'>ZAPLACENO</div>");
		}
		$('#content').append("<div class='list-point'>ČÍSLO FAKTURY: <span class='to-the-right'>" + accounts[currentAccount].invoices[currentInvoice].id + "</span></div>");
		$('#content').append("<div class='list-point'>DATUM VYDÁNÍ: <span class='to-the-right'>" + accounts[currentAccount].invoices[currentInvoice].datelabel + "</span></div>");
		$('#content').append("<div class='list-point'>SPLATITEL: <span class='to-the-right'>" + accounts[currentAccount].invoices[currentInvoice].ownerlabel + "</span></div>");
		$('#content').append("<div class='list-point'>VYDAVATEL: <span class='to-the-right'>" + accounts[currentAccount].invoices[currentInvoice].senderlabel + "</span></div>");
		for(var i = 0; i < accounts[currentAccount].invoices[currentInvoice].points.length; i++){
			$('#content').append("<div class='list-point shorter lighter'>" + accounts[currentAccount].invoices[currentInvoice].points[i].label + "<span class='to-the-right'>$" + accounts[currentAccount].invoices[currentInvoice].points[i].price + "</span></div>");
		}
		$('#content').append("<div class='list-point'>CELKOVÁ CENA: <span class='to-the-right'>$" + accounts[currentAccount].invoices[currentInvoice].price + "</span></div>");
		if(accounts[currentAccount].invoices[currentInvoice].payed <= 0 && currentPermissions.payinvoice){
			$('#content').append("<div onclick=\"setinvoicepaid('" + accounts[currentAccount].invoices[currentInvoice].id + "')\" class='list-point activate'>OZNAČIT FAKTURU ZA ZAPLACENOU</div>");
		}
	}else if(name == "access"){
		$('#content').html("");
		var anyone = false;
		var access = accounts[currentAccount].access_list;
		if(access.job.name != "none"){
			$('#content').append("<div class='list-point'>AUTOMATICKÝ PŘÍSTUP PRO ZAMĚSTNANCE SPOLEČNOSTI: " + access.job.name + "<span class='to-the-right'>NA POZICI S VÁHOU: " + access.job.grade + "</span></div>");
			anyone = true;
		}

		for(var i = 0; i < access.users.length; i++){
			anyone = true;
			if(i == 0) $('#content').append("<div class='list-point'>Seznam uživatelů s přístupem:</div>");

			$('#content').append("<div onclick=\"selectaccess('" + i + "')\" class='list-point shorter red-activate'>" + access.users[i].name + "</div>");
		}

		if(!anyone){
			$('#content').append("<div class='list-point'>NIKDO, KROMĚ MAJITELE, NEMÁ PŘÍSTUP NA BANKOVNÍ ÚČET</div>");
		}

		$('#content').append("<div onclick=\"addaccess()\" class='list-point activate'>PŘIDAT OPRÁVNĚNÍ NA ÚČET</div>");
	}else if(name == "access-select"){
		var access = accounts[currentAccount].access_list.users[currentAccess];
		$('#content').html("<div class='list-point'>KŘESTNÍ JMÉNO A PŘIJMENÍ: <span class='to-the-right'>" + access.name + "</span></div>");
		if(access.permissions != null){
			if(access.permissions.balance != null){
				$('#content').append("<div id='perm-balance' onclick=\"changeperm('balance')\" class='list-point shorter " + (access.permissions.balance ? 'activate' : 'red-activate') + "'>ZŮSTATEK BANKOVNÍHO ÚČTU: <span id='perm-title-balance' class='to-the-right'>" + exchangevaluefortext(access.permissions.balance) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { balance : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.withdraw_take != null){
				$('#content').append("<div id='perm-withdraw_take' onclick=\"changeperm('withdraw_take')\" class='list-point shorter " + (access.permissions.withdraw_take ? 'activate' : 'red-activate') + "'>VÝBĚR Z ÚČTU: <span id='perm-title-withdraw_take' class='to-the-right'>" + exchangevaluefortext(access.permissions.withdraw_take) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { withdraw_take : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.withdraw_put != null){
				$('#content').append("<div id='perm-withdraw_put' onclick=\"changeperm('withdraw_put')\" class='list-point shorter " + (access.permissions.withdraw_put ? 'activate' : 'red-activate') + "'>VKLAD NA ÚČET: <span id='perm-title-withdraw_put' class='to-the-right'>" + exchangevaluefortext(access.permissions.withdraw_put) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { withdraw_put : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.transfer != null){
				$('#content').append("<div id='perm-transfer' onclick=\"changeperm('transfer')\" class='list-point shorter " + (access.permissions.transfer ? 'activate' : 'red-activate') + "'>PLATBY: <span id='perm-title-transfer' class='to-the-right'>" + exchangevaluefortext(access.permissions.transfer) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { transfer : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.changetype != null){
				$('#content').append("<div id='perm-changetype' onclick=\"changeperm('changetype')\" class='list-point shorter " + (access.permissions.changetype ? 'activate' : 'red-activate') + "'>ZMĚNIT TYP ÚČTU: <span id='perm-title-changetype' class='to-the-right'>" + exchangevaluefortext(access.permissions.changetype) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { changetype : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.changeowner != null){
				$('#content').append("<div id='perm-changeowner' onclick=\"changeperm('changeowner')\" class='list-point shorter " + (access.permissions.changeowner ? 'activate' : 'red-activate') + "'>ZMĚNIT MAJITELE ÚČTU: <span id='perm-title-changeowner' class='to-the-right'>" + exchangevaluefortext(access.permissions.changeowner) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { changeowner : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.changename != null){
				$('#content').append("<div id='perm-changename' onclick=\"changeperm('changename')\" class='list-point shorter " + (access.permissions.changename ? 'activate' : 'red-activate') + "'>ZMĚNIT NÁZEV ÚČTU: <span id='perm-title-changename' class='to-the-right'>" + exchangevaluefortext(access.permissions.changename) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { changename : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.access != null){
				$('#content').append("<div id='perm-access' onclick=\"changeperm('access')\" class='list-point shorter " + (access.permissions.access ? 'activate' : 'red-activate') + "'>SPRÁVA UŽIVATELŮ: <span id='perm-title-access' class='to-the-right'>" + exchangevaluefortext(access.permissions.access) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { access : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.invoices != null){
				$('#content').append("<div id='perm-invoices' onclick=\"changeperm('invoices')\" class='list-point shorter " + (access.permissions.invoices ? 'activate' : 'red-activate') + "'>SEZNAM FAKTUR: <span id='perm-title-invoices' class='to-the-right'>" + exchangevaluefortext(access.permissions.invoices) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { invoices : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.payinvoice != null){
				$('#content').append("<div id='perm-payinvoice' onclick=\"changeperm('payinvoice')\" class='list-point shorter " + (access.permissions.payinvoice ? 'activate' : 'red-activate') + "'>ZAPLATIT FAKTURU: <span id='perm-title-payinvoice' class='to-the-right'>" + exchangevaluefortext(access.permissions.payinvoice) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { payinvoice : false }, account: currentAccount,target: access.id})); 
			
			if(access.permissions.cards != null){
				$('#content').append("<div id='perm-cards' onclick=\"changeperm('cards')\" class='list-point shorter " + (access.permissions.cards ? 'activate' : 'red-activate') + "'>SPRÁVA PLATEBNÍCH KARET: <span id='perm-title-cards' class='to-the-right'>" + exchangevaluefortext(access.permissions.cards) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { cards : false }, account: currentAccount,target: access.id})); 

			if(access.permissions.delete != null){
				$('#content').append("<div id='perm-delete' onclick=\"changeperm('delete')\" class='list-point shorter " + (access.permissions.delete ? 'activate' : 'red-activate') + "'>SMAZAT ÚČET: <span id='perm-title-delete' class='to-the-right'>" + exchangevaluefortext(access.permissions.delete) + "</span></div>");
			}else $.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { delete : false }, account: currentAccount,target: access.id})); 
		}else{
			$.post('http://bank/action', JSON.stringify({
				action: "updatepermission",
				current: "default",
				account: currentAccount,
				target: access.id
			}));
		}
		$('#content').append("<div onclick=\"removeaccess(" + access.id + ")\" class='list-point red-activate'>Odebrat osobě přístup</div>");
	}else if(name == "cards"){
		var cards = accounts[currentAccount].cards;
		var count = 0;
		$('#content').html("<div class='list-point'>DOSTUPNÉ PLATEBNÍ KARTY:</div>");
		$.each(cards, function(key, value) {
			count++;
			$('#content').append("<div onclick=\"selectcard('" + key + "')\" class='list-point activate shorter'>PLATEBNÍ KARTA " + cards[key].id + ": <span class='to-the-right'>" + cards[key].description + "</span></div>");
		});

		if(count <= 0){
			$('#content').append("<div class='list-point red-point ignore'>NEMÁTE ŽÁDNOU PLATEBNÍ KARTU</div>");
		}

		$('#content').append("<div onclick=\"opencontent('card-create')\" class='list-point activate'>ZAŽÁDAT O NOVOU PLATEBNÍ KARTU</div>");
	}else if(name == "card-create"){
		$('#content').html("<div class='block'><input type='text' id='input-text' placeholder='Zadejte přístupový kód platební karty [max. 8 znaků, nejen čísel]'><button onclick=\"createcard()\" class='activate' type='submit' id='btn-card-create'>Zažádat o kartu</button></div>");
	}else if(name == "card-select"){
		var card = accounts[currentAccount].cards[currentCard];
		$('#content').html("<div class='list-point'>IDENTIFIKACE KARTY: <span class='to-the-right'>" + card.id + "</span></div>");
		$('#content').append("<div class='list-point'>PŘÍSTUPOVÉ HESLO: <span class='to-the-right'>" + card.code + "</span></div>");
		$('#content').append("<div onclick=\"opencontent('card-rename')\" class='list-point activate'>POPIS KARTY: <span class='to-the-right'>" + card.description + "</span></div>");
		// $('#content').append("<div class='list-point'>POSLEDNÍ VÝBĚR V HODNOTĚ: <span class='to-the-right'>$" + card.lastTaken + "</span></div>");
		if(card.blocked > 0){
			if(card.blockedLabel != null){
				$('#content').append("<div class='list-point red-point'>KARTA BYLA ZABLOKOVÁNA (" + card.blockedLabel + ")</div>");
			}else{
				$('#content').append("<div class='list-point red-point'>KARTA BYLA ZABLOKOVÁNA</div>");
			}

			$('#content').append("<div onclick=\"blockcard('unblock')\" class='list-point activate shorter' id='block-card'>ODBLOKOVAT KARTU</div>");
		}else{
			$('#content').append("<div onclick=\"blockcard('block')\" class='list-point red-activate shorter' id='block-card'>ZABLOKOVAT KARTU</div>");
		}

		$('#content').append("<div onclick=\"deletecard()\" class='list-point red-activate'>ZRUŠIT PLATEBNÍ KARTU</div>");
	}else if(name == "card-rename"){
		var card = accounts[currentAccount].cards[currentCard];

		$('#content').html("<div class='block'><input type='text' id='input-text' value='" + card.description + "'><button onclick=\"renamecard()\" class='activate' type='submit' id='btn-card-create'>Zpracovat požadavek</button></div>");
	}else if(name == "cashmachine-login"){
		$('#content').html("<div class='block'><input type='text' id='input-text' placeholder='Zadejte přístupový kód'><button onclick=\"logincard()\" class='activate' type='submit' id='btn-card-login'>Vstoupit</button></div>");
	}else if(name == "cash-machine"){
		$('#content').html("<div class='list-point'>Aktuální stav účtu: <span class='balance-" + currentAccount + "'>$" + inMachineAccount.balance + "</span></div>");
		$('#content').append("<div class='block'><input type='number' id='input-number' placeholder='0' min='0'><button onclick='withdraw(\"withdraw-put\")' class='activate' type='submit' id='btn-withdraw-put'>Vložit peníze na účet</button><button onclick='withdraw(\"withdraw-take\")' class='activate' type='submit' id='btn-withdraw-take'>Vybrat peníze z účtu</button></div>");
	}else if(name == "personalinvoices"){
		var count = 0;
		$('#content').html("");
		$.each(accounts.personalinvoices, function(key, value) {
			if(accounts.personalinvoices[key].payed <= 0){
				count++;
				$('#content').append("<div onclick=\"selectunpersonalinvoice('" + key + "')\" class='list-point red-activate'><span class='to-the-left'>" + accounts.personalinvoices[key].id + "</span><span class='in-the-middle'>$" + accounts.personalinvoices[key].price + "</span><span class='to-the-right'>" + accounts.personalinvoices[key].ownerlabel + "</span></div>");
			}
		});

		if(count<=0){
			$('#content').html("<div class='list-point'>ŽÁDNÉ NEZAPLACENÉ FAKTURY</div>");
		}
	}else if(name == "payinvoice"){
		$('#content').html("<div class='list-point ignore'>Číslo faktury: <span class='to-the-right'>" + currentInvoice + "</span></div>");
		$('#content').html("<div class='list-point ignore'>Částka k zaplacení: <span class='to-the-right'>$" + accounts.personalinvoices[currentInvoice].price + "</span></div>");
		$('#content').append("<div onclick=\"payinvoice('cash', 'none')\" class='list-point activate shorter'>ZAPLATIT HOTOVĚ</div>");
		$('#content').append("<div onclick=\"opencontent('selectaccount-invoicepayment')\" class='list-point activate shorter'>ZAPLATIT PŘEVODEM</div>");
	}else if(name == "selectaccount-invoicepayment"){
		$('#content').html("<div class='list-point ignore'>Zvolte bankovní účet pro úhradu faktury</div>");
		$('#content').append('<ul>');
		var count = 0;
		$.each(accounts, function(key, value) {
			if(key != 'personalinvoices' && key != "fines"){
				count++;
				var accounttype = "OSOBNÍ ÚČET";
				if(accounts[key].access_list.job.name != "none"){
					accounttype = "FIREMNÍ ÚČET";
				}
				$('#content').append("<li onclick=\"payinvoice('bank', '" + key +"')\" class='list-point activate'><span class='to-the-left type-" + key + "'>" + accounttype + ": " + key + "</span><span class='in-the-middle description-"+ key + "'>" + accounts[key].description + "</span></span></li>");
			}
		});

		if(count<=0){
			$('#content').append("<li onclick=\"opencontent('newaccount')\" class='list-point activate'>NEMÁTE ŽÁDNÝ DOSTUPNÝ ÚČET</li>");
		}
		
		$('#content').append('</ul>');
	}else if(name == "fines"){
		var count = 0;
		$('#content').html("");
		$.each(accounts.fines, function(key, value) {
			if(accounts.fines[key].payed <= 0){
				count++;
				$('#content').append("<div onclick=\"selectfine(" + key + ")\" class='list-point red-activate'><span class='to-the-left'>" + accounts.fines[key].label + "</span><span class='in-the-middle'>$" + accounts.fines[key].price + "</span><span class='to-the-right'>" + accounts.fines[key].datelabel + "</span></div>");
			}
		});
		if(count<=0){
			$('#content').html("<div class='list-point'>ŽÁDNÉ POKUTY</div>");
		}
	}else if(name == "payfine"){
		$('#content').html("<div class='list-point ignore'>Pokuta k zaplacení: <span class='to-the-right'>" + accounts.fines[currentFine].label + "</span></div>");
		$('#content').html("<div class='list-point ignore'>Částka: <span class='to-the-right'>$" + accounts.fines[currentFine].price + "</span></div>");
		$('#content').append("<div onclick=\"payfine('cash', 'none')\" class='list-point activate shorter'>ZAPLATIT HOTOVĚ</div>");
		$('#content').append("<div onclick=\"opencontent('selectaccount-finepayment')\" class='list-point activate shorter'>ZAPLATIT PŘEVODEM</div>");
	}else if(name == "selectaccount-finepayment"){
		$('#content').html("<div class='list-point ignore'>Zvolte bankovní účet pro úhradu pokuty</div>");
		$('#content').append('<ul>');
		var count = 0;
		$.each(accounts, function(key, value) {
			if(key != 'personalinvoices' && key != "fines"){
				count++;
				var accounttype = "OSOBNÍ ÚČET";
				if(accounts[key].access_list.job.name != "none"){
					accounttype = "FIREMNÍ ÚČET";
				}
				$('#content').append("<li onclick=\"payfine('bank', '" + key + "')\" class='list-point activate'><span class='to-the-left type-" + key + "'>" + accounttype + ": " + key + "</span><span class='in-the-middle description-"+ key + "'>" + accounts[key].description + "</span></span></li>");
			}
		});

		if(count<=0){
			$('#content').append("<li onclick=\"opencontent('newaccount')\" class='list-point activate'>NEMÁTE ŽÁDNÝ DOSTUPNÝ ÚČET</li>");
		}
		
		$('#content').append('</ul>');
	}
}

function payfine(type, selectedaccount){
	if(type == "bank"){
		var account = accounts[selectedaccount]
		if(account.balance >= accounts.fines[currentFine].price){
			$.post("http://bank/action", JSON.stringify({
				action: "payfine",
				price: accounts.fines[currentFine].price,
				fineId: currentFine,
				type: type,
				account: selectedaccount
			}));
			opencontent("accountlist");
		}else notify("warning", "Úhrada za pokutu", "Vámi vybraný bankovní účet nemá dostatečný zůstatek na uhrazení pokuty");
	}else{
		$.post("http://bank/action", JSON.stringify({
			action: "payfine",
			price: accounts.fines[currentFine].price,
			fineId: currentFine,
			type: type
		}));
		opencontent("accountlist");
	}
}

function payinvoice(type, selectedaccount){
	if(type == "bank"){
		var account = accounts[selectedaccount]
		if(account.balance >= accounts.personalinvoices[currentInvoice].price){
			$.post("http://bank/action", JSON.stringify({
				action: "payinvoice",
				price: accounts.personalinvoices[currentInvoice].price,
				invoice: accounts.personalinvoices[currentInvoice],
				type: type,
				account: selectedaccount
			}));
			opencontent("accountlist");
		}else notify("warning", "Úhrada za fakturu", "Vámi vybraný bankovní účet nemá dostatečný zůstatek na uhrazení faktury");
	}else{
		$.post("http://bank/action", JSON.stringify({
			action: "payinvoice",
			price: accounts.personalinvoices[currentInvoice].price,
			invoiceId: accounts.personalinvoices[currentInvoice].id,
			type: type
		}));
		opencontent("accountlist");
	}
}

function changeperm(permission){
	var access = accounts[currentAccount].access_list.users[currentAccess];

	if(access.permissions[permission]){
		$('#perm-'+permission).addClass('red-activate');
		$('#perm-'+permission).removeClass('activate');

		access.permissions[permission] = false;
	}else{
		$('#perm-'+permission).removeClass('red-activate');
		$('#perm-'+permission).addClass('activate');

		access.permissions[permission] = true;
	}

	$('#perm-title-'+permission).html(exchangevaluefortext(access.permissions[permission]));
	$.post('http://bank/action', JSON.stringify({ action: "updatepermission", current: { [permission] : access.permissions[permission] }, account: currentAccount,target: access.id}));
}

function openmenu(name){
	if(name == "main"){
		currentAccount = 0;
		currentInvoice = 0;
		currentAccess = 0;

		$('#logged-menu').hide();
		$('#cashmachine-menu').hide();
		$('#unlogged-menu').show();
	}else if(name == "account"){
		$('#unlogged-menu').hide();
		$('#cashmachine-menu').hide();
		$('#logged-menu').show();
	}else{
		$('#logged-menu').hide();
		$('#cashmachine-menu').show();
		$('#unlogged-menu').hide();
	}
}

function closepanel(){
	$.post('http://bank/closepanel', JSON.stringify({}));
}

function exchangevaluefortext(value){
	if(value) return "PŘÍSTUP POVOLEN";
	else return "PŘÍSTUP OMEZEN";
}

function notify(type, title, text){
	$.post("http://bank/notify", JSON.stringify({
		type: type,
		title: title,
		text: text
	}));
}

function copyToClipboard(element) {
	var $temp = $("<input>");
	$("body").append($temp);
	$temp.val($(element).html()).select();
	document.execCommand("copy");
	$temp.remove();
}