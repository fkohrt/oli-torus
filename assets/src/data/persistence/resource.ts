import { ProjectSlug, ResourceSlug } from 'data/types';
import { AttachedObjectives, BibPointer, PageContent } from '../content/resource';
import { makeRequest } from './common';

export type ResourceUpdate = {
  title: string;
  objectives: AttachedObjectives;
  content: PageContent;
  releaseLock: boolean;
};

// TODO: server responding with revision_slug instead of revisionSlug as expected
export type Edited = { type: 'success'; revisionSlug: string; revision_slug?: string };

export function edit(
  project: ProjectSlug,
  resource: ResourceSlug,
  pendingUpdate: ResourceUpdate,
  releaseLock: boolean,
) {
  const update = Object.assign({}, pendingUpdate, { releaseLock });

  // Index "citation references" in the "content" and elevate them as top-level list
  const citationRefs: BibPointer[] = [];
  traverseContent(update.content.model, (key: string, value: any) => {
    if (!value) {
      return;
    }
    if (value.type === 'cite') {
      citationRefs.push({ type: 'bibentry', id: value.bibref });
    }
    if (value.type === 'activity-reference') {
      citationRefs.push({ type: 'activity', id: value.activitySlug });
    }
  });
  update.content.bibrefs = citationRefs;

  const params = {
    method: 'PUT',
    body: JSON.stringify({ update }),
    url: `/project/${project}/resource/${resource}`,
  };

  return makeRequest<Edited>(params);
}

export type Page = { id: string; title: string };
export type PagesReceived = { type: 'success'; pages: Page[] };

// Requests all of the page details for a course for the purpose
// of constructing links
export function pages(project: ProjectSlug, current?: string) {
  const currentSlug = current === undefined ? '' : `?current=${current}`;

  const params = {
    method: 'GET',
    url: `/project/${project}/link${currentSlug}`,
  };

  return makeRequest<PagesReceived>(params);
}

function traverseContent(o: any, func: any) {
  for (const i in o) {
    func.apply(this, [i, o[i]]);
    if (o[i] !== null && typeof o[i] == 'object') {
      traverseContent(o[i], func);
    }
  }
}
