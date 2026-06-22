'use strict';

/**
 * @module routes/page/random
 *
 * Provides /page/random/summary — returns a random article's summary.
 * This endpoint was originally part of RESTBase, not mobileapps.
 * The Wikipedia mobile app expects it, so we implement it here by:
 *   1. Querying MediaWiki API for a random main-namespace page
 *   2. Internally fetching the summary via a local HTTP request
 *
 * We proxy internally rather than 302 redirecting because Traefik rewrites
 * the path prefix (/api/rest_v1/ → /{domain}/v1/), so a redirect to the
 * internal path would not match the ingress route externally.
 */

const http = require('http');
const sUtil = require('../../lib/util');
const api = require('../../lib/api-util');

const router = sUtil.router();

let app;

/**
 * GET {domain}/v1/page/random/summary
 * Returns a summary of a random article in the main namespace.
 */
router.get('/random/summary', (req, res) => {
	const domain = req.params.domain;

	// Query MediaWiki API for a random main-namespace page
	return api.mwApiGet(req, {
		action: 'query',
		list: 'random',
		rnnamespace: 0,
		rnlimit: 1
	}).then((apiRes) => {
		const random = apiRes.body && apiRes.body.query && apiRes.body.query.random;
		if (!random || !random.length) {
			throw new sUtil.HTTPError({
				status: 404,
				type: 'not_found',
				title: 'No random page found',
				detail: 'The wiki returned no random pages'
			});
		}

		const title = encodeURIComponent(random[0].title);
		const summaryPath = `/${ domain }/v1/page/summary/${ title }`;

		// Fetch the summary from ourselves (same process, same port)
		return new Promise((resolve, reject) => {
			const proxyReq = http.get({
				hostname: '127.0.0.1',
				port: app.conf.port || 8888,
				path: summaryPath,
				headers: {
					'user-agent': req.headers['user-agent'] || app.conf.user_agent,
					'accept-language': req.headers['accept-language'] || 'en'
				}
			}, (proxyRes) => {
				// Copy status and headers
				res.status(proxyRes.statusCode);
				const passthroughHeaders = ['content-type', 'etag', 'cache-control'];
				passthroughHeaders.forEach((h) => {
					if (proxyRes.headers[h]) {
						res.set(h, proxyRes.headers[h]);
					}
				});
				// Pipe body
				proxyRes.pipe(res);
				proxyRes.on('end', resolve);
			});
			proxyReq.on('error', reject);
		});
	}).catch((err) => {
		if (err && err.status) {
			throw err;
		}
		throw new sUtil.HTTPError({
			status: 502,
			type: 'api_error',
			title: 'MediaWiki API error',
			detail: (err && err.message) || 'Failed to fetch random page'
		});
	});
});

module.exports = function(appObj) {
	app = appObj;
	return {
		path: '/page',
		api_version: 1,
		router
	};
};
