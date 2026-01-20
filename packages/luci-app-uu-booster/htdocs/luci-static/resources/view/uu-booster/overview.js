'use strict';
'require form';
'require rpc';
'require view';
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
				status: {
					version: _('Not installed'),
					running: false,
					update_available: false
				},
				actions: {}
			};
		}).then(function(data) {
			const running_status = !!data.running_status;
			const update_available = !!data.update_available;
			return {
				status: {
					version: data.installed_version || _('Not installed'),
					running: running_status,
					update_available: update_available ? _('Update Available') : _('No update'),
				},
				actions: {
					update: update_available,
					start: !running_status,
					stop: running_status,
					restart: running_status,
				}
			};
		});
	},

	render: function(data) {
		var m, s, o;

		m = new form.JSONMap(data, _('UU Game Booster'));

		s = m.section(form.TypedSection, 'status', _('Status'));
		s.anonymous = true;
		o = s.option(form.Flag, 'running', _('Running'));
		o.readonly = true;
		o = s.option(form.DummyValue, 'version', _('Installed Version'));
		o = s.option(form.DummyValue, 'update_available', _('Update'))

		s = m.section(form.TypedSection, 'actions', _('Services'));
		s.anonymous = true;
		o = s.option(form.Button, 'update_available', _(''))
		o.title = '&#160;';
		o.inputtitle = _('Update');
		o.readonly = !data.actions.update;
		o.inputstyle = 'action';
		o.onclick = L.bind(function(ev) {
			return callExecuteUpdate()
				.then(L.bind(m.load, m))
				.then(L.bind(m.render, m))
		});
		o = s.option(form.Button, 'start');
		o.title = '&#160;';
		o.readonly = !data.actions.start;
		o.inputtitle = _('Start');
		o.inputstyle = 'action';
		o.onclick = L.bind(function(ev) {
			return callStartService()
				.then(L.bind(m.load, m))
				.then(L.bind(m.render, m))
		});

		o = s.option(form.Button, 'stop');
		o.title = '&#160;';
		o.readonly = !data.actions.stop;
		o.inputtitle = _('Stop');
		o.inputstyle = 'action';
		o.onclick = L.bind(function(ev) {
			return callStopService()
				.then(L.bind(m.load, m))
				.then(L.bind(m.render, m))
		});
		o = s.option(form.Button, 'restart');
		o.title = '&#160;';
		o.readonly = !data.actions.restart;
		o.inputtitle = _('Restart');
		o.inputstyle = 'action';
		o.onclick = L.bind(function(ev) {
			return callRestartService()
				.then(L.bind(m.load, m))
				.then(L.bind(m.render, m))
		});

		return m.render();
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
