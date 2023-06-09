/*
 * Copyright 2007-2017 Charles du Jeu - Abstrium SAS <team (at) pyd.io>
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



import React, {Component} from 'react'
import Player from './Player';

// The threeSixytPlayer is the same for all badges
// var threeSixtyPlayer = new ThreeSixtyPlayer();

export default class Preview extends Component {

    componentDidMount() {
        this.loadNode(this.props)
    }

    componentWillReceiveProps(nextProps) {
        if (nextProps.node !== this.props.node) {
            this.loadNode(nextProps)
        }
    }

    loadNode(props) {
        const {pydio, node} = props
        var baseURL = pydio.Parameters.get('ajxpServerAccess');
        if(baseURL.includes("?")) {
            baseURL += '&get_action=audio_proxy&file=' + encodeURIComponent(HasherUtils.base64_encode(node.getPath()));
        }
        else {
            baseURL += '?get_action=audio_proxy&file=' + encodeURIComponent(HasherUtils.base64_encode(node.getPath()));
        }
        this.setState({
            path: node.getPath(),
            url: baseURL,
            mimeType: "audio/" + node.getAjxpMime()
        })
    }

    render() {
        const {mimeType, path, url} = this.state || {}

        if (!url) return null

        return (
            <Player id={path} url={url} rich={true} style={{width: 250, height: 200, margin: "auto"}} onReady={() => {}} />
        );
    }
}

function guid() {
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
}

function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
        .toString(16)
        .substring(1);
}
