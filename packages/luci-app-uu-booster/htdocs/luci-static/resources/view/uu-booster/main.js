'use strict';
'require view';
'require rpc';
'require poll';
'require dom';

return view.extend({
	render: function() {
		let statusDiv, versionSpan, latestSpan, updateBtn, checkBtn;
		let pollHandle;
		const rpc = luci.rpc.declare({
			object: 'luci-app-uu-booster',
			method: 'uu-booster',
			params: ['name'],
			expect: { status: {}, check_version: {}, update: {} }
		});
		
		let container = E('div', { 'class': 'cbi-section' }, [
			E('h2', {}, [_('UU Game Booster')]),
			
			E('div', { 'class': 'cbi-section-descr' }, [
				E('div', { 'class': 'cbi-value' }, [
					E('strong', {}, [_('Service Status:')]),
					E('span', { 'id': 'status-text' }, ['Loading...'])
				])
			]),
			
			E('div', { 'class': 'cbi-dvalue-desc' }, [
				E('label', {}, [_('Current Version:')]),
				E('span', { 'id': 'current-version' }, ['Loading...'])
			]),
			
			E('div', { 'class': 'cbi-dvalue-desc' }, [
				E('label', {}, [_('Latest Version:')]),
				E('span', { 'id': 'latest-version' }, ['--'])
			]),
			
			E('div', { 'class': 'cbi-section-actions' }, [
				E('button', { 
					'class': 'cbi-button cbi-button-action', 
					'id': 'check-version-btn',
					'click': this.checkVersion.bind(this)
				}, [_('Check for Updates')]),
				
				E('button', { 
					'class': 'cbi-button cbi-button-action', 
					'id': 'update-btn', 
					'disabled': true,
					'click': this.updateBooster.bind(this)
				}, [_('Update to Latest')]),
				
				E('button', { 
					'class': 'cbi-button cbi-button-find', 
					'click': this.refreshStatus.bind(this)
				}, [_('Refresh Status')])
			]),
			
			E('div', { 
				'class': 'alert-message', 
				'id': 'message-box', 
				'style': 'display:none;'
			})
		]);
		
		statusDiv = container.querySelector('#status-text').parentNode;
		versionSpan = container.querySelector('#current-version');
		latestSpan = container.querySelector('#latest-version');
		checkBtn = container.querySelector('#check-version-btn');
		updateBtn = container.querySelector('#update-btn');
		
		this.refreshStatus();
		
		pollHandle = L.poll.add(this.refreshStatus.bind(this), 30);
		
		L.bind('view-destroy', function() {
			L.poll.remove(pollHandle);
		});
		
		return container;
	},
	
	checkVersion: function(ev) {
		let self = this;
		let checkBtn = document.getElementById('check-version-btn');
		let updateBtn = document.getElementById('update-btn');
		
		checkBtn.disabled = true;
		checkBtn.textContent = _('Checking...');
		updateBtn.disabled = true;
		
		return rpc('check_version')
			.then(function(data) {
				checkBtn.disabled = false;
				checkBtn.textContent = _('Check for Updates');
				
				if (data.success) {
					let latestSpan = document.getElementById('latest-version');
					latestSpan.textContent = data.latest_version;
					
					let versionSpan = document.getElementById('current-version');
					let currentVersion = versionSpan.textContent;
					
					if (currentVersion !== data.latest_version) {
						updateBtn.disabled = false;
						self.showMessage(_('New version available!'), 'info');
					} else {
						self.showMessage(_('Already up to date'), 'success');
					}
				} else {
					self.showMessage(data.error || _('Failed to check version'), 'error');
				}
			})
			.catch(function(err) {
				checkBtn.disabled = false;
				checkBtn.textContent = _('Check for Updates');
				self.showMessage(_('Failed to check version'), 'error');
			});
	},
	
	updateBooster: function(ev) {
		let self = this;
		let updateBtn = document.getElementById('update-btn');
		
		updateBtn.disabled = true;
		updateBtn.textContent = _('Updating...');
		
		let messageBox = document.getElementById('message-box');
		messageBox.style.display = 'none';
		
		return rpc('update')
			.then(function(data) {
				updateBtn.disabled = false;
				updateBtn.textContent = _('Update to Latest');
				
				if (data.success) {
					self.showMessage(data.message || _('Update completed successfully'), 'success');
					setTimeout(function() {
						location.reload();
					}, 2000);
				} else {
					self.showMessage(data.message || _('Update failed'), 'error');
				}
			})
			.catch(function(err) {
				updateBtn.disabled = false;
				updateBtn.textContent = _('Update to Latest');
				self.showMessage(_('Update failed'), 'error');
			});
	},
	
	refreshStatus: function() {
		let statusDiv = document.getElementById('status-text').parentNode;
		let statusText = document.getElementById('status-text');
		
		return rpc('status')
			.then(function(data) {
				if (data.current_version) {
					document.getElementById('current-version').textContent = data.current_version;
				}
				
				if (data.service_status) {
					statusText.textContent = data.service_status;
				} else {
					statusText.textContent = 'Not running';
				}
			})
			.catch(function(err) {
				document.getElementById('current-version').textContent = 'Failed to load';
				document.getElementById('status-text').textContent = 'Error';
			});
	},
	
	showMessage: function(message, type) {
		let messageBox = document.getElementById('message-box');
		messageBox.textContent = message;
		messageBox.className = 'alert-message ' + type;
		messageBox.style.display = 'block';
		
		setTimeout(function() {
			messageBox.style.display = 'none';
		}, 5000);
	}
});
