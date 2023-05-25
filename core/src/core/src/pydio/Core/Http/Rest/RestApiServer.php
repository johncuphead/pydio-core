<?php
/*
 * Copyright 2007-2017 Abstrium <contact (at) pydio.com>
 * This file is part of Pydio.
 *
 * Pydio is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Pydio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with Pydio.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The latest code can be found at <https://pydio.com>.
 */

namespace Pydio\Core\Http\Rest;

use Pydio\Core\Http\Server;
use Pydio\Core\Services\ApplicationState;
use Pydio\Core\Services\ConfService;
use Tuupola\Middleware\Cors;

defined('AJXP_EXEC') or die('Access not allowed');

/**
 * Class RestApiServer
 * REST API listener
 * @package Pydio\Core\Http\Rest
 */
class RestApiServer extends Server
{
    /**
     * RestApiServer constructor.
     * @param $base
     * @param array $requestAttributes
     */
    public function __construct($base, $requestAttributes = [])
    {
        parent::__construct($base, $requestAttributes);
        ApplicationState::setSapiRestBase($base);
    }

    protected function stackMiddleWares()
    {
        $origin = array_map('trim', explode(',', ConfService::getGlobalConf("CORS_ORIGIN")));
        $methods = array_map('trim', explode(',', ConfService::getGlobalConf("CORS_METHODS")));
        $headersAllow = array_map('trim', explode(',', ConfService::getGlobalConf("CORS_HEADERS_ALLOW")));
        $headersExpose = array_map('trim', explode(',', ConfService::getGlobalConf("CORS_HEADERS_EXPOSE")));

        $this->middleWares->push(array("Pydio\\Core\\Controller\\Controller", "registryActionMiddleware"));
        $this->middleWares->push(array("Pydio\\Core\\Http\\Rest\\RestAuthMiddleware", "handleRequest"));
        $this->middleWares->push(new Cors([
            "origin" => $origin,
            "methods" => $methods,
            "headers.allow" => $headersAllow,
            "headers.expose" => $headersExpose,
            "credentials" => true,
            "cache" => 0
        ]));

        $this->topMiddleware = new RestApiMiddleware($this->base);
        $this->middleWares->push(array($this->topMiddleware, "handleRequest"));
    }
}
