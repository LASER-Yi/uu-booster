'use strict';
'require form';
'require rpc';
'require ui';

const callGetStatus = rpc.declare({
	object: 'uu-booster',
	method: 'get_status',
	params: []
});

const callExecuteUpdate = rpc.declare({
	object: 'uu-booster',
	method: 'execute_update',
	params: []
});

const callStartService = rpc.declare({
	object: 'uu-booster',
	method: 'start_service',
	params: []
});

const callStopService = rpc.declare({
	object: 'uu-booster',
	method: 'stop_service',
	params: []
});

const callRestartService = rpc.declare({
	object: 'uu-booster',
	method: 'restart_service',
	params: []
});

return view.extend({
	load: function() {
		return callGetStatus().catch(function(e) {
			return {
				available: false,
				installed_version: '',
				running_status: 0,
				status_text: 'RPC service unavailable',
				update_available: false
			};
		});
	},

	render: function(data) {
		var m, s, o;
		var disabledAttr = data.available ? {} : { 'disabled': 'disabled' };

		m = new form.Map(null, _('UU Game Booster'));

		s = m.section(form.NamedSection, null, null, _('Status'));
		s.render = function() {
			var version = data.installed_version || 'Not installed';
			var running = data.running_status === 1;
			var updateAvailable = data.update_available;

			return E('div', { 'class': 'cbi-section-node' }, [
				E('div', { 'style': 'display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0;' }, [
					E('div', { 'style': 'padding: 15px; background-color: #f5f5f5; border-radius: 4px;' }, [
						E('h4', { 'style': 'margin: 0 0 10px 0; color: #616161;' }, _('Installed Version')),
						E('div', { 'style': 'font-size: 16px; font-weight: 500;' }, version)
					]),
					E('div', { 'style': 'padding: 15px; background-color: #f5f5f5; border-radius: 4px;' }, [
						E('h4', { 'style': 'margin: 0 0 10px 0; color: #616161;' }, _('Running Status')),
						E('div', {}, running 
							? E('span', { 'style': 'color: #00c853; font-weight: 500;' }, _('Running'))
							: E('span', { 'style': 'color: #d32f2f; font-weight: 500;' }, _('Stopped'))
						)
					]),
					E('div', { 'style': 'padding: 15px; background-color: #f5f5f5; border-radius: 4px;' }, [
						E('h4', { 'style': 'margin: 0 0 10px 0; color: #616161;' }, _('Update Status')),
						E('div', {}, updateAvailable
							? E('span', { 'style': 'color: #ff9800; font-weight: 500;' }, _('Update Available'))
							: E('span', { 'style': 'color: #757575;' }, _('Up to date'))
						)
					])
				])
			]);
		};

		s = m.section(form.NamedSection, null, null, _('Service Control'));
		s.render = function() {
			return E('div', { 'class': 'cbi-section-node' }, [
				E('div', { 'style': 'display: flex; flex-wrap: wrap; gap: 10px;' }, [
					E('button', Object.assign({
						'class': 'cbi-button cbi-button-action',
						'click': ui.createHandlerFn(this, function(ev) {
							var btn = ev.target;
							btn.disabled = true;

							return callExecuteUpdate().then(function(result) {
								ui.showModal(_('Update Complete'), [
									E('div', { 'style': 'max-height: 400px; overflow-y: auto; background-color: #f5f5f5; padding: 15px; border-radius: 4px; margin: 15px 0;' }, [
										E('pre', { 'style': 'white-space: pre-wrap; font-family: monospace; margin: 0;' }, result.output || 'No output')
									]),
									E('div', { 'style': 'text-align: right; margin-top: 15px;' }, [
										E('button', {
											'class': 'cbi-button cbi-button-positive',
											'click': function() {
												ui.hideModal();
												location.reload();
											}
										}, _('Done'))
									])
								]);
							}).always(function() {
								btn.disabled = false;
							});
						})
					}), _('Update')),
					E('button', Object.assign({
						'class': 'cbi-button',
						'click': ui.createHandlerFn(this, function(ev) {
							var btn = ev.target;
							btn.disabled = true;

							return callStartService().then(function() {
								location.reload();
							}).always(function() {
								btn.disabled = false;
							});
						})
					}, disabledAttr), _('Start')),
					E('button', Object.assign({
						'class': 'cbi-button',
						'click': ui.createHandlerFn(this, function(ev) {
							var btn = ev.target;
							btn.disabled = true;

							return callStopService().then(function() {
								location.reload();
							}).always(function() {
								btn.disabled = false;
							});
						})
					}, disabledAttr), _('Stop')),
					E('button', Object.assign({
						'class': 'cbi-button',
						'click': ui.createHandlerFn(this, function(ev) {
							var btn = ev.target;
							btn.disabled = true;

							return callRestartService().then(function() {
								location.reload();
							}).always(function() {
								btn.disabled = false;
							});
						})
					}, disabledAttr), _('Restart'))
				])
			]);
		};

		return m.render();
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
